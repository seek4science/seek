# A class to represent a file with a git version. Holds refernces to the version, the git blob object from Rugged, and the path
# where the blob exists in the repository.
module Git
  class Blob
    include Seek::ContentExtraction
    include ActiveModel::Serialization

    delegate_missing_to :@blob
    delegate :git_repository, :version, :git_base, to: :git_version

    attr_reader :git_version, :path
    alias_method :original_filename, :path

    def initialize(git_version, blob, path)
      @git_version = git_version
      @blob = blob
      @path = path
    end

    def annotations
      git_version.git_annotations.where(path: path)
    end

    def url
      git_version.remote_sources[path]
    end

    def read
      file_contents(as_text: true)
    end

    def binread
      file_contents
    end

    def file_contents(as_text: false, fetch_remote: false, &block)
      if fetch_remote && remote? && !fetched?
        if block_given?
          block.call(remote_content)
        else
          remote_content.read
        end
      else
        if block_given?
          block.call(StringIO.new(as_text ? text : content)) # Rugged does not support streaming blobs :(
        else
          as_text ? text : content
        end
      end
    end

    def remote?
      url.present?
    end

    def fetched?
      !empty?
    end

    def empty?
      size == 0
    end

    def ==(other)
      return super unless other.is_a?(Git::Blob)

      git_version == other.git_version &&
        path == other.path &&
        oid == other.oid
    end

    def to_crate_entity(crate, type: ::ROCrate::File, properties: {})
      type.new(crate, StringIO.new(file_contents), path).tap do |entity|
        entity['url'] = url if url.present?
        entity['contentSize'] = size
        entity.properties = entity.raw_properties.merge(properties)
      end
    end

    def text_contents_for_search
      content = []
      unless binary?
        text = file_contents
        unless text.blank?
          content = filter_text_content text
          content = split_content(content,10,5)
        end
      end
      content
    end

    def remote_content
      return unless remote?
      handler = ContentBlob.remote_content_handler_for(url)
      return unless handler
      io = handler.fetch
      io.rewind
      io
    end

    def cache_key
      "#{git_repository.id}-#{oid}"
    end

    def notebook
      Rails.cache.fetch("notebook-#{cache_key}") do
        f = Tempfile.new('ipynb')
        f.binmode
        f.write(file_contents)
        f.rewind
        `jupyter nbconvert --to html #{f.path} --stdout`
      end
    end

    def content_path(opts = {})
      opts.reverse_merge!(version: @git_version.version, path: path)
      Seek::Util.routes.polymorphic_path([@git_version.resource, :git_raw], opts)
    end

    def file_extension
      path.split('/').last&.split('.')&.last&.downcase
    end

    def content_type_file_extensions
      [file_extension]
    end

    def content_type
      @content_type ||= content_types.first
    end

    def content_types
      mime_types_for_extension(file_extension)
    end

    def file_size
      size
    end

    def is_text?
      !binary?
    end
  end
end
