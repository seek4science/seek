# A class to represent a file with a git version. Holds refernces to the version, the git blob object from Rugged, and the path
# where the blob exists in the repository.
module Seek
  module Git
    class Tree
      delegate_missing_to :@tree
      delegate :git_repository, :version, :git_base, to: :git_version

      attr_reader :git_version, :path

      def initialize(git_version, tree, path = '/')
        @git_version = git_version
        @tree = tree
        @path = path
      end

      def get_tree(path)
        entry = entry(path)
        return nil unless entry[:type] == :tree
        o = git_base.lookup(entry[:oid])
        Seek::Git::Tree.new(git_version, o, path) if o
      end

      def get_blob(path)
        entry = entry(path)
        return nil unless entry[:type] == :blob
        o = git_base.lookup(entry[:oid])
        Seek::Git::Blob.new(git_version, o, path) if o
      end

      def entry(path)
        @tree.path(path)
      end

      def trees
        each_tree.map do |entry|
          Seek::Git::Tree.new(git_version, object(entry[:path]), entry[:path])
        end
      end

      def blobs
        each_blob.map do |entry|
          Seek::Git::Blob.new(git_version, object(entry[:path]), entry[:path])
        end
      end

      def total_size
        total = 0

        walk_blobs do |_, entry|
          blob = git_base.lookup(entry[:oid])
          total += blob.size
        end

        total
      end
    end
  end
end