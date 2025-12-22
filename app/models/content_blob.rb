require 'digest/md5'
require 'shrine'
require 'tmpdir'
require 'docsplit'

class ContentBlob < ApplicationRecord
  include Seek::ContentTypeDetection
  include Seek::ContentExtraction
  include Shrine::FileUploader::Attachment(:file)
  extend Seek::UrlValidation
  prepend Seek::Openbis::Blob
  prepend Nels::Blob

  belongs_to :asset, polymorphic: true, autosave: false

  # Store HTTP headers to stop multiple requests when retrieving file info
  attr_writer :headers

  acts_as_uniquely_identifiable

  before_save :check_version
  after_create :create_retrieval_job
  before_save :clear_sample_type_matches
  after_destroy :delete_converted_files

  has_many :worksheets, inverse_of: :content_blob, dependent: :destroy

  validate :original_filename_or_url

  delegate :read, :close, :rewind, :download, :open, to: :shrine_file

  include Seek::Data::Checksums

  CHUNK_SIZE = 2 ** 12

  def shrine_file
    if respond_to?(:file_attacher) && file_attacher&.attached?
      file_attacher.file
    else
      raise Exception, 'No file attached for this content blob'
    end
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
    shrine_file.download do |temp_file|
      yield temp_file.path
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

  def check_version
    self.asset_version = asset.version if asset_version.nil? && !asset.nil? && asset.respond_to?(:version)
  end

  def show_as_external_link?
    return false if custom_integration? || url.blank?
    return true if unhandled_url_scheme?
    no_local_copy = !stored_in_shrine?
    html_content = is_webpage? || content_type == 'text/html'
    show_as_link = Seek::Config.show_as_external_link_enabled ? no_local_copy : html_content
    show_as_link
  end

  def cache_key
    base = new_record? ? "#{model_name.cache_key}/new" : "#{model_name.cache_key}/#{id}"

    unless url.nil?
      "#{base}-#{sha1sum}-#{Digest::SHA1.hexdigest(url)}"
    else
      "#{base}-#{sha1sum}"
    end
  end

  def stored_in_shrine?
    respond_to?(:file_attacher) && file_attacher&.attached?
  end

  def file
    raise Exception, 'No valid file found' unless stored_in_shrine?
    shrine_file
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
    !stored_in_shrine? && url.blank?
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

  def create_retrieval_job
    if Seek::Config.cache_remote_files && !stored_in_shrine? && !url.blank? && (make_local_copy || cachable?) && remote_content_handler
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
