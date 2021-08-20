# A class to represent a file with a git version. Holds refernces to the version, the git blob object from Rugged, and the path
# where the blob exists in the repository.
module Seek
  module Git
    class Blob
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

      def file_contents(&block)
        if block_given?
          block.call(StringIO.new(content)) # Rugged does not support streaming blobs :(
        else
          content
        end
      end

      def ==(other)
        git_version == other.git_version &&
        path == other.path &&
        oid == other.oid
      end
    end
  end
end