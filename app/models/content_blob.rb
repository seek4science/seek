require 'digest/md5'
require 'net/http'
require 'open-uri'
require 'tmpdir'
require 'docsplit'
require 'rest-client'
require "shrine/attachment"

class ContentBlob < ApplicationRecord
  include Seek::ContentTypeDetection
  include Seek::ContentExtraction
  include Shrine::FileUploader::Attachment(:file)
  extend Seek::UrlValidation
  prepend Seek::Openbis::Blob
  prepend Nels::Blob

  belongs_to :asset, polymorphic: true, autosave: false

  # the actual data value stored in memory. If this could be large, then using :tmp_io_object is preferred
  attr_writer :data

  # this is used as an alternative to passing the data contents directly (in memory).
  # it is not stored in the database, but when the content_blob is saved, the IO object is read and stored in the correct location.
  # if the file doesn't exist an error occurs
  attr_writer :tmp_io_object

  # Store HTTP headers to stop SEEK performing multiple requests when getting info
  attr_writer :headers

  acts_as_uniquely_identifiable

  # this action saves the contents of @data or the contents contained within the @tmp_io_object to the storage file.
  # an Exception is raised if both are defined
  before_save :dump_data_to_file
  before_save :check_version
  after_create :create_retrieval_job
  before_save :clear_sample_type_matches
  after_destroy :delete_converted_files

  has_many :worksheets, inverse_of: :content_blob, dependent: :destroy

  validate :original_filename_or_url

  delegate :read, :close, :rewind, :path, to: :file

  include Seek::Data::Checksums

  CHUNK_SIZE = 2 ** 12

  acts_as_fleximage do
    image_directory Seek::Config.temporary_filestore_path + '/image_assets'
    use_creation_date_based_directories false
    image_storage_format :png
    require_image false
    invalid_image_message 'was not a readable image'
  end

  acts_as_fleximage_extension

  # This overrides the method from acts_as_fleximage so that the original image is read from the default SEEK filestore
  #  rather than the special `image_directory` specified above. Resized images will still go in there, though.
  def file_path
    filepath
  end

  def original_filename_or_url
    if original_filename.blank?
      if url.blank?
        errors.add(:base, 'Need to specify either original_filename or url')
      elsif !valid_url?(url)
        errors.add(:url, 'is invalid')
      end
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

  # Open the blob data regardless of storage backend; yields IO when block given.
  def open_file
    return nil unless file_exists?

    io = if stored_in_shrine?
           file.open
         else
           File.open(filepath, 'rb')
         end

    return io unless block_given?

    begin
      yield io
    ensure
      io.close if io.respond_to?(:close)
    end
  end

  # Download (or copy) the blob into a Tempfile and yield the Tempfile.
  def with_tempfile
    return nil unless file_exists?

    if stored_in_shrine?
      tempfile = file.download
      begin
        yield tempfile
      ensure
        tempfile.close! if tempfile.respond_to?(:close!)
      end
    else
      with_temporary_copy do |path|
        Tempfile.open(File.basename(path)) do |tmp|
          FileUtils.cp(path, tmp.path)
          tmp.flush
          yield tmp
        end
      end
    end
  end

  # Stream each chunk of the blob. Returns an enumerator when no block is supplied.
  def stream_each_chunk(chunk_size = CHUNK_SIZE)
    return enum_for(:stream_each_chunk, chunk_size) unless block_given?

    open_file do |io|
      io.rewind if io.respond_to?(:rewind)
      while (chunk = io.read(chunk_size))
        yield chunk
      end
    end
  end

  def read_all(encoding: nil)
    open_file do |io|
      io.rewind if io.respond_to?(:rewind)
      data = io.read
      data = data.force_encoding(encoding) if encoding && data.respond_to?(:force_encoding)
      data
    end
  end

  def file_extension
    split_filename = original_filename&.split('.')
    if split_filename && split_filename.length > 2
      extension = split_filename[-2, 2]&.join('.')&.downcase
      return extension unless mime_types_for_extension(extension).empty?
    end
    split_filename&.last&.downcase
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
    return false if custom_integration? || url.blank?
    return true if unhandled_url_scheme?
    no_local_copy = !file_exists?
    html_content = is_webpage? || content_type == 'text/html'
    show_as_link = Seek::Config.show_as_external_link_enabled ? no_local_copy : html_content
    show_as_link
  end
  # include all image types

  def cache_key
    base = new_record? ? "#{model_name.cache_key}/new" : "#{model_name.cache_key}/#{id}"

    unless url.nil?
      "#{base}-#{sha1sum}-#{Digest::SHA1.hexdigest(url)}"
    else
      "#{base}-#{sha1sum}"
    end
  end

  # returns an IO Object to the data content, or nil if the data file doesn't exist.
  # In the case that there is a URL defined, but no local copy, the IO Object is still nil.
  def data_io_object
    return @tmp_io_object unless @tmp_io_object.nil?
    return StringIO.new(@data) unless @data.nil?
    open_file
  end

  # Check if the file is stored in Shrine (and hence in S3 as per the configured storage)
  def stored_in_shrine?
    respond_to?(:file_attacher) && file_attacher&.attached?
  end

  # Check if the file exists (delegates to Shrine or local file fallback)
  def file_exists?
    if stored_in_shrine?
      file_attacher&.file.present?
    else
      File.exist?(filepath)
    end
  rescue Shrine::FileNotFound
    false
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
    raise Exception, 'You cannot define both :data content and a :tmp_io_object' unless @data.nil? || @tmp_io_object.nil?
    check_uuid
    if @tmp_io_object.nil?
      dump_data_object_to_file
    else
      dump_tmp_io_object_to_file
    end
  end

  def file
    if file_exists?
      return file_attacher.file
    end
  end

  def retrieve
    self.tmp_io_object = remote_content_handler.fetch
    save
  end

  def cachable?
    Seek::Config.cache_remote_files &&
      !is_webpage? &&
      file_size &&
      file_size < Seek::Config.max_cachable_size
  end

  def search_terms
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

  def url_search_terms
    if url
      url_ignore_terms = %w[http https www com co org uk de]
      url_search_terms = [url, url.split(/\W+/)].flatten - url_ignore_terms
    else
      url_search_terms = []
    end
    url_search_terms
  end

  # whether this content blob represents a custom integration, such as integrated with openBIS
  def custom_integration?
    openbis? || nels?
  end

  def is_downloadable?
    !show_as_external_link?
  end

  def unhandled_url_scheme?
    !remote_content_handler
  end

  def no_content?
    (!file_size || file_size == 0) && url.blank?
  end

  def remote_content_handler
    self.class.remote_content_handler_for(url)
  end

  def self.remote_content_handler_for(url)
    return nil unless valid_url?(url)
    uri = URI(url)
    case uri.scheme
    when 'ftp'
      Seek::DownloadHandling::FTPHandler.new(url)
    when 'http', 'https'
      if uri.hostname.include?('github.com') || uri.hostname.include?('raw.githubusercontent.com')
        Seek::DownloadHandling::GithubHTTPHandler.new(url)
      elsif Seek::DownloadHandling::GalaxyHTTPHandler.is_galaxy_workflow_url?(uri)
        Seek::DownloadHandling::GalaxyHTTPHandler.new(url)
      else
        Seek::DownloadHandling::HTTPHandler.new(url)
      end
    end
  end

  def valid_url?(url)
    self.class.valid_url?(url)
  end

  has_task :remote_content_fetch

  def content_path(opts = {})
    opts.reverse_merge!(action: 'download')
    Seek::Util.routes.polymorphic_path([asset, self], opts)
  end

  def content_type_file_extensions
    mime_extensions(content_type)
  end

  private

  def remote_headers
    @headers ||= (remote_content_handler.info rescue {})
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
    raise Exception, 'You cannot define both :data content and a :tmp_io_object' unless @data.nil? || @tmp_io_object.nil?
    return unless @tmp_io_object

    if @tmp_io_object.respond_to?(:path)
      @tmp_io_object.flush if @tmp_io_object.respond_to? :flush
      if @tmp_io_object.path
        FileUtils.cp @tmp_io_object.path, filepath

        # only clean up if object is within the temp (/tmp/) directory, otherwise the original file should be kept
        if @tmp_io_object.path.start_with?("#{Dir.tmpdir}#{File::SEPARATOR}")
          File.delete(@tmp_io_object.path)
        end

      end

    else
      @tmp_io_object.rewind
      File.open(filepath, 'wb+') do |f|
        until (chunk = @tmp_io_object.read(CHUNK_SIZE)).nil?
          f.write(chunk)
        end
      end
    end
    @tmp_io_object = nil
  end

  def calculate_file_size
    self.file_size = if file_exists?
                       if stored_in_shrine?
                         file&.size || file&.metadata&.dig('size')
                       else
                         File.size(filepath)
                       end
                     elsif url
                       remote_headers[:file_size]
                     end
  end

  def create_retrieval_job
    if Seek::Config.cache_remote_files && !file_exists? && !url.blank? && (make_local_copy || cachable?) && remote_content_handler
      RemoteContentFetchingJob.perform_later(self)
    end
  end

  def clear_sample_type_matches
    Rails.cache.delete_matched("st-match-#{id}*") if changed?
  end

  # cleans up any files converted to txt or pdf, if they exist
  def delete_converted_files
    return unless self[:uuid].present?
    %w[pdf txt].each do |format|
      path = filepath(format)
      FileUtils.rm(path) if File.exist?(path)
    end
  end

  def delete_image_file
    return unless self[:uuid].present?
    super
  end
end
