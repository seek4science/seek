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

  DATA_STORAGE_PATH = "filestore/content_blobs/"
  
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

  before_create :check_url_content_type, :unless =>  "Seek::Config.is_virtualliver"

  has_many :worksheets, :dependent => :destroy


  # For VL, asset uploaded with url can be manually marked as an external link or not, and NO asset will be stored in both cases.
  #User can go to the url if it is an external link, otherwise use can directly download the asset from that url.
  #While for SysMO, asset uploaded with url with text/html format(checked with call_back functions before content_blob is created)) is tagged to be is_webpage, and asset will be stored if user ticks make_a_copy checkbox
  # this should be removed when external_link is merged with is_webpage in db schema
  alias_attribute :is_webpage, :external_link if Seek::Config.is_virtualliver

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
    return StringIO.new(data_old) unless data_old.nil?
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
    return "#{storage_directory}/#{storage_filename(format,uuid_to_use)}"
  end

  def storage_directory
    if Rails.env == "test"
      path = ContentBlob.test_storage_location
    else
      path = "#{Rails.root}/#{DATA_STORAGE_PATH}/#{Rails.env}"
    end
    FileUtils.mkdir_p(path)
    return path
  end

  #The location contentblobs are stored when Rails.env='test' - this is only used for unit/functional testing purposes.
  def self.test_storage_location
    "#{Rails.root}/tmp/test_content_blobs"
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
    data_to_save ||= self.data_old
    
    if !data_to_save.nil?
      File.open(filepath,"w+") do |f|      
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

        File.open(filepath, "w+") do |f|
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
