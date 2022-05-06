# A class to represent a file with a git version. Holds refernces to the version, the git blob object from Rugged, and the path
# where the blob exists in the repository.
module Git
  class Blob
    include Seek::ContentExtraction
    include ActiveModel::Serialization

    delegate_missing_to :@blob
    delegate :git_repository, :version, :git_base, to: :git_version

    attr_reader :git_version, :path

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

    def file_contents(fetch_remote: false, &block)
      if fetch_remote && remote? && !fetched?
        if block_given?
          block.call(remote_content)
        else
          remote_content.read
        end
      else
        if block_given?
          block.call(StringIO.new(content)) # Rugged does not support streaming blobs :(
        else
          content
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
  end
end
