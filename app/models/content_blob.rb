require 'digest/md5'
require 'net/http'
require 'open-uri'
require 'tmpdir'
require 'docsplit'
require 'rest-client'

class ContentBlob < ActiveRecord::Base
  include Seek::ContentTypeDetection
  include Seek::ContentExtraction
  include Seek::Data::Checksums

  belongs_to :asset, polymorphic: true

  # the actual data value stored in memory. If this could be large, then using :tmp_io_object is preferred
  attr_writer :data

  # this is used as an alternative to passing the data contents directly (in memory).
  # it is not stored in the database, but when the content_blob is saved, the IO object is read and stored in the correct location.
  # if the file doesn't exist an error occurs
  attr_writer :tmp_io_object

  # Flag to decide whether a remote file should be retrieved and stored in SEEK
  attr_accessor :make_local_copy

  acts_as_uniquely_identifiable

  # this action saves the contents of @data or the contents contained within the @tmp_io_object to the storage file.
  # an Exception is raised if both are defined
  before_save :dump_data_to_file
  before_save :check_version
  before_save :calculate_file_size
  after_create :create_retrieval_job

  has_many :worksheets, dependent: :destroy

  validate :original_filename_or_url

  delegate :read, :close, :rewind, :path, to: :file

  def original_filename_or_url
    if original_filename.blank? && url.blank?
      errors.add(:base, 'Need to specify either original_filename or url')
    end
  end

  def spreadsheet_annotations
    worksheets.map { |worksheet| worksheet.cell_ranges.map(&:annotations) }.flatten
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

  def check_version
    self.asset_version = asset.version if asset_version.nil? && !asset.nil? && asset.respond_to?(:version)
  end

  def show_as_external_link?
    no_local_copy =  !file_exists?
    html_content =  is_webpage? || content_type == 'text/html'
    show_as_link = Seek::Config.show_as_external_link_enabled ? no_local_copy : html_content
    !url.blank? && (show_as_link || unhandled_url_scheme?)
  end
  # include all image types

  def cache_key
    "#{super}-#{sha1sum}"
  end

  # returns an IO Object to the data content, or nil if the data file doesn't exist.
  # In the case that there is a URL defined, but no local copy, the IO Object is still nil.
  def data_io_object
    return @tmp_io_object unless @tmp_io_object.nil?
    return StringIO.new(@data) unless @data.nil?
    return File.open(filepath, 'rb') if file_exists?
    nil
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
    Seek::Config.asset_filestore_path
  end

  def converted_storage_directory
    Seek::Config.converted_filestore_path
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
    FileUtils.mkdir_p path unless File.exist?(path)
    path
  end

  acts_as_fleximage do
    image_directory (Seek::Config.temporary_filestore_path + '/image_assets')
    use_creation_date_based_directories false
    image_storage_format :png
    require_image false
    invalid_image_message 'was not a readable image'
  end

  acts_as_fleximage_extension

  def copy_image
    copy_to_path = image_assets_storage_directory
    copy_to_path << "/#{id}.#{ContentBlob.image_storage_format}"
    if file_exists? && !File.exist?(copy_to_path)
      FileUtils.cp filepath, copy_to_path
    end
  end

  def file
    @file ||= File.open(filepath)
  end

  def retrieve
    self.tmp_io_object = remote_content_handler.fetch
    self.save
  end

  def cachable?
    Seek::Config.cache_remote_files &&
        !is_webpage? &&
        file_size &&
        file_size < Seek::Config.max_cachable_size
  end

  def caching_job(ignore_locked = true)
    job_yaml = RemoteContentFetchingJob.new(self).to_yaml

    if ignore_locked
      Delayed::Job.where(['handler = ? AND locked_at IS NULL AND failed_at IS NULL', job_yaml]) # possibly a better way of doing this...
    else
      Delayed::Job.where(['handler = ? AND failed_at IS NULL', job_yaml])
    end
  end

  def search_terms
    if url
      url_ignore_terms = ['http','https','www','com','co','org','uk','de']
      url_search_terms = [url,url.split(/\W+/)].flatten - url_ignore_terms
    else
      url_search_terms = []
    end
    if is_text?
      if is_indexable_text?
        [original_filename, url, file_extension, text_contents_for_search] | url_search_terms
      else
        [original_filename, url, file_extension] | url_search_terms
      end
    else
      [original_filename, url, file_extension, pdf_contents_for_search] | url_search_terms
    end

  end

  def is_downloadable?
    !show_as_external_link?
  end

  def unhandled_url_scheme?
    !remote_content_handler
  end

  private

  def remote_headers
    if @headers
      @headers
    else
      begin
        RestClient.head(url).headers
      rescue
        {}
      end
    end
  end

  def retrieve_content_type_from_url
    type = remote_headers[:content_type] || ''

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

  def calculate_file_size
    if file_exists?
      self.file_size = File.size(self.filepath)
    elsif url
      self.file_size = remote_headers[:content_length]
    else
      self.file_size = nil
    end
  end

  def create_retrieval_job
    if Seek::Config.cache_remote_files && !file_exists? && !url.blank? && (make_local_copy || cachable?) && remote_content_handler
      RemoteContentFetchingJob.new(self).queue_job
    end
  end

  def remote_content_handler
    case URI(self.url).scheme
      when 'ftp'
        Seek::DownloadHandling::FTPHandler.new(self.url)
      when 'http', 'https'
        Seek::DownloadHandling::HTTPHandler.new(self.url)
      else
        nil
    end
  end
end
