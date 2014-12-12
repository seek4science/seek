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

  belongs_to :asset, polymorphic: true

  # the actual data value stored in memory. If this could be large, then using :tmp_io_object is preferred
  attr_writer :data

  # this is used as an alternative to passing the data contents directly (in memory).
  # it is not stored in the database, but when the content_blob is saved is save, the IO object is read and stored in the correct location.
  # if the file doesn't exist an error occurs
  attr_writer :tmp_io_object

  acts_as_uniquely_identifiable

  # this action saves the contents of @data or the contents contained within the @tmp_io_object to the storage file.
  # an Exception is raised if both are defined
  before_save :dump_data_to_file

  before_save :calculate_md5

  before_save :check_version
  
  before_create :check_content_type

  has_many :worksheets, dependent: :destroy

  validate :original_filename_or_url

  def original_filename_or_url
    if original_filename.blank? && url.blank?
      errors.add(:base, 'Need to specifiy either original_filename or url')
    end
  end

  def spreadsheet_annotations
    worksheets.map { |w| w.cell_ranges.map { |c| c.annotations } }.flatten
  end

  # returns the size of the file in bytes, or nil if the file doesn't exist
  def filesize
    if file_exists?
      File.size(filepath)
    else
      nil
    end
  end

  # allows you to run something on a temporary copy of the blob file, which is deleted once finished
  # e.g. blob.with_temporary_copy{|copy_path| <some stuff with the copy>}
  def with_temporary_copy
    copy_path = make_temp_copy
    begin
      yield copy_path
    ensure
      FileUtils.rm(copy_path)
    end
  end

  def file_extension
    original_filename && original_filename.split('.').last
  end

  def make_temp_copy
    temp_name = Time.now.strftime('%Y%m%d%H%M%S%L') + '-' + original_filename
    temp_path = File.join(Seek::Config.temporary_filestore_path, temp_name).to_s
    FileUtils.cp(filepath, temp_path)
    temp_path
  end

  def original_content_type
    read_attribute(:content_type)
  end

  def is_binary_file?
    original_content_type == 'application/octet-stream'
  end

  def content_type
    is_binary_file? ? find_or_keep_type_with_mime_magic : original_content_type
  end

  def unknown_file_type?
    human_content_type == 'Unknown file type'
  end

  def find_or_keep_type_with_mime_magic
    mime = MimeMagic.by_extension(file_extension)
    mime ||= MimeMagic.by_magic(File.open filepath)
    mime.try(:type) || original_content_type
  end

  def human_content_type
    mime_nice_name(content_type)
  end

  def check_version
    if asset_version.nil? && !asset.nil?
      self.asset_version = asset.version
    end
  end

  def show_as_external_link?
    no_local_copy =  !file_exists?
    html_content =  is_webpage? || content_type == 'text/html'
    show_as_link = Seek::Config.show_as_external_link_enabled ? no_local_copy : html_content
    !url.blank? && show_as_link
  end
  # include all image types
  def is_image?
    content_type ? content_type.index('image') == 0 : false
  end

  def md5sum
    if super.nil?
      other_changes = self.changed?
      calculate_md5
      # only save if there are no other changes - this is to avoid inadvertantly storing other potentially unwanted changes
      save unless other_changes
    end
    super
  end

  def cache_key
    "#{super}-#{md5sum}"
  end

  # returns an IO Object to the data content, or nil if the data file doesn't exist.
  # In the case that there is a URL defined, but no local copy, the IO Object is still nil.
  def data_io_object
    return @tmp_io_object unless @tmp_io_object.nil?
    return StringIO.new(@data) unless @data.nil?
    return File.open(filepath, 'rb') if file_exists?
    nil
  end

  def calculate_md5
    # FIXME: only recalculate if the data has changed (should be able to do this with changes.keys.include?("data") or along those lines).
    if file_exists?
      digest = Digest::MD5.new
      digest.file(filepath)
      self.md5sum = digest.hexdigest
    end
  end

  def file_exists?
    File.exist?(filepath)
  end

  def storage_filename(format = 'dat', uuid_to_use = nil)
    uuid_to_use ||= uuid
    "#{uuid_to_use}.#{format}"
  end

  def filepath(format = 'dat', uuid_to_use = nil)
    if format == 'dat'
      File.join(data_storage_directory, storage_filename(format, uuid_to_use))
    else
      File.join(converted_storage_directory, storage_filename(format, uuid_to_use))
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
    fail Exception.new('You cannot define both :data content and a :tmp_io_object') unless @data.nil? || @tmp_io_object.nil?
    check_uuid
    unless @tmp_io_object.nil?
      dump_tmp_io_object_to_file
    else
      dump_data_object_to_file
    end
  end

  def image_assets_storage_directory
    path = Seek::Config.temporary_filestore_path + '/image_assets'
    unless File.exist?(path)
      FileUtils.mkdir_p path
    end
    path
  end

  acts_as_fleximage do
    image_directory (Seek::Config.temporary_filestore_path + '/image_assets')
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

  def check_content_type
    if url
      set_content_type_according_to_url
    elsif unknown_file_type? && file_exists?
      set_content_type_according_to_file
    end
  end

  def set_content_type_according_to_file
    self.content_type = find_or_keep_type_with_mime_magic
  end

  def set_content_type_according_to_url
    type = retrieve_content_type_from_url
    if type == 'text/html'
      self.is_webpage = true
      self.content_type = type
    end
    self.content_type = type if unknown_file_type?
  rescue => exception
    self.is_webpage = false
    Rails.logger.warn("There was a problem reading the headers for the URL of the content blob = #{url}")
  end

  def retrieve_content_type_from_url
    response = RestClient.head url
    type = response.headers[:content_type] || ''

    # strip out the charset, e.g for content-type  "text/html; charset=utf-8"
    type.gsub(/;.*/, '').strip
  end

  def dump_data_object_to_file
    data_to_save = @data

    unless data_to_save.nil?
      File.open(filepath, 'wb+') do |f|
        f.write(data_to_save)
      end
    end
  end

  def dump_tmp_io_object_to_file
    fail Exception.new('You cannot define both :data content and a :tmp_io_object') unless @data.nil? || @tmp_io_object.nil?
    return unless @tmp_io_object

    if @tmp_io_object.is_a?(StringIO)
      @tmp_io_object.rewind
      File.open(filepath, 'wb+') do |f|
        f.write @tmp_io_object.read
      end
    else
      @tmp_io_object.flush if @tmp_io_object.respond_to? :flush
      FileUtils.mv @tmp_io_object.path, filepath
    end
    @tmp_io_object = nil
  end
end
