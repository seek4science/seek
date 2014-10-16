require 'digest/md5'
require 'net/http'
require 'open-uri'
require 'tmpdir'
require 'docsplit'
require 'rest-client'

class ContentBlob < ActiveRecord::Base

  include Seek::ContentTypeDetection
  include Seek::PdfExtraction
  include Seek::MimeTypes

  belongs_to :asset, :polymorphic => true
  
  #the actual data value stored in memory. If this could be large, then using :tmp_io_object is preferred
  attr_writer :data
  
  #this is used as an alternative to passing the data contents directly (in memory).
  #it is not stored in the database, but when the content_blob is saved is save, the IO object is read and stored in the correct location.
  #if the file doesn't exist an error occurs
  attr_writer :tmp_io_object
  
  acts_as_uniquely_identifiable
  
  #this action saves the contents of @data or the contents contained within the @tmp_io_object to the storage file.
  #an Exception is raised if both are defined
  before_save :dump_data_to_file
  
  before_save :calculate_md5

  before_save :check_version

  #is_webpage: whether text/html
  #MERGENOTE, FIXME: this isn't correct. it is possible to not make a local copy and also not display an external link
  #external_link: true means no local copy, false means local copy. Set true by default on upload page.
  before_create :check_url_content_type

  has_many :worksheets, :dependent => :destroy


  validate :original_filename_or_url

  def original_filename_or_url
    if original_filename.blank? && url.blank?
      errors.add(:base, "Need to specifiy either original_filename or url")
    end
  end

  def spreadsheet_annotations
    worksheets.collect {|w| w.cell_ranges.collect {|c| c.annotations}}.flatten
  end

  #returns the size of the file in bytes, or nil if the file doesn't exist
  def filesize
    if file_exists?
      File.size(filepath)
    else
      nil
    end
  end

  def human_content_type
    mime_nice_name(content_type)
  end
  
  def check_version
    if asset_version.nil? && !asset.nil?
      self.asset_version = asset.version
    end
  end

  #include all image types
  def is_image?
    self.content_type.nil?? false : self.content_type.index('image')== 0
  end

  def md5sum
    if super.nil?
      other_changes=self.changed?
      calculate_md5
      #only save if there are no other changes - this is to avoid inadvertantly storing other potentially unwanted changes
      save unless other_changes
    end
    super
  end

  def cache_key
    "#{super}-#{md5sum}"
  end
  
  #returns an IO Object to the data content, or nil if the data file doesn't exist. 
  # In the case that there is a URL defined, but no local copy, the IO Object is still nil.
  def data_io_object
    return @tmp_io_object unless @tmp_io_object.nil?
    return StringIO.new(@data) unless @data.nil? 
    return File.open(filepath,"rb") if file_exists?
    return nil
  end
  
  def calculate_md5
    #FIXME: only recalculate if the data has changed (should be able to do this with changes.keys.include?("data") or along those lines).
    if file_exists?
      digest = Digest::MD5.new
      digest.file(filepath)
      self.md5sum = digest.hexdigest
    end
  end        
  
  def file_exists?
    File.exist?(filepath)
  end

  def storage_filename format="dat",uuid_to_use=nil
    uuid_to_use ||= uuid
    "#{uuid_to_use}.#{format}"
  end

  def filepath format='dat',uuid_to_use=nil
    if format=="dat"
     File.join(data_storage_directory,storage_filename(format,uuid_to_use))
    else
      File.join(converted_storage_directory,storage_filename(format,uuid_to_use))
    end
  end

  def data_storage_directory
    path = Seek::Config.asset_filestore_path
    unless File.exist?(path)
      FileUtils.mkdir_p path
    end
    path
  end

  def converted_storage_directory
    path = Seek::Config.converted_filestore_path
    unless File.exist?(path)
      FileUtils.mkdir_p path
    end
    path
  end

  def dump_data_to_file        
    raise Exception.new("You cannot define both :data content and a :tmp_io_object") unless @data.nil? || @tmp_io_object.nil?
    check_uuid
    unless @tmp_io_object.nil?
      dump_tmp_io_object_to_file
    else
      dump_data_object_to_file
    end    
  end

  def image_assets_storage_directory
    path = Seek::Config.temporary_filestore_path + "/image_assets"
    unless File.exist?(path)
      FileUtils.mkdir_p path
    end
    path
  end

  acts_as_fleximage do
    image_directory (Seek::Config.temporary_filestore_path + "/image_assets")
    use_creation_date_based_directories false
    image_storage_format :jpg
    output_image_jpg_quality 85
    require_image false
    invalid_image_message 'was not a readable image'
  end

  acts_as_fleximage_extension

  def copy_image
    copy_to_path = image_assets_storage_directory + "/#{id}.jpg"
    if file_exists? && !File.exist?(copy_to_path)
      FileUtils.cp filepath, copy_to_path
    end
  end

  private

  def check_url_content_type
    unless url.nil?
      begin
        response = RestClient.head url
        type = response.headers[:content_type] || ""

        #strip out the charset, e.g for content-type  "text/html; charset=utf-8"
        type = type.gsub(/;.*/,"").strip
        if type == "text/html"
          self.is_webpage = true
          self.content_type = type
        end

        self.content_type = type if self.human_content_type == "Unknown file type"
      rescue Exception=>e
        self.is_webpage = false
        Rails.logger.warn("There was a problem reading the headers for the URL of the content blob = #{self.url}")
      end
    end
  end
  
  def dump_data_object_to_file
    data_to_save = @data
    
    if !data_to_save.nil?
      File.open(filepath,"wb+") do |f|
        f.write(data_to_save)    
      end
    end
  end
  
  def dump_tmp_io_object_to_file
    raise Exception.new("You cannot define both :data content and a :tmp_io_object") unless @data.nil? || @tmp_io_object.nil?
    t1 = Time.now
    unless @tmp_io_object.nil?
      begin
        logger.info "Moving #{@tmp_io_object.path} to #{filepath}"
        @tmp_io_object.flush if @tmp_io_object.respond_to? :flush
        FileUtils.mv @tmp_io_object.path, filepath
        @tmp_io_object = nil
      rescue Exception => e
        logger.info "Falling back to ruby copy because of: #{e.message}"
        @tmp_io_object.rewind

        File.open(filepath, "wb+") do |f|
          buffer=""
          while @tmp_io_object.read(16384, buffer)
            f << buffer
          end
        end
        @tmp_io_object.rewind
        @tmp_io_object=nil
      end
    end
    logger.info "TIME: dump_tmp_io_object_to_file took #{Time.now - t1}"
  end
  
end
