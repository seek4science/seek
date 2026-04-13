module Seek
  module Storage
    # LocalAdapter stores files on the local filesystem.
    # It is a thin wrapper around File/FileUtils that presents
    # the same interface that S3Adapter will implement, so that the rest of the code can be agnostic to the storage backend.

    # All methods take a `key` which is a filename like "uuid.dat" or "uuid.pdf".
    # The adapter is initialised with a `base_path` (e.g. Seek::Config.asset_filestore_path)
    # and builds full paths as File.join(base_path, key).
    class LocalAdapter
      def initialize(base_path:)
        @base_path = base_path
      end

      # Write String or IO content to storage.
      # If content responds to :read (IO/StringIO/Tempfile), it is read in chunks.
      # If content is a String or binary blob, it is written directly.
      def write(key, content)
        File.open(full_path(key), 'wb+') do |f|
          if content.respond_to?(:read)
            content.rewind if content.respond_to?(:rewind)
            until (chunk = content.read(CHUNK_SIZE)).nil?
              f.write(chunk)
            end
          else
            f.write(content) unless content.nil?
          end
        end
      end

      # Copy a file that already exists at local_src path into storage under key.
      def copy_from_path(local_src, key)
        FileUtils.cp(local_src, full_path(key))
      end

      # Returns an open read-only File object for the stored content.
      # The caller is responsible for closing it.
      def open(key)
        File.open(full_path(key), 'rb')
      end

      # Returns true if the file for key exists in storage.
      def exist?(key)
        File.exist?(full_path(key))
      end

      # Deletes the file for key if it exists. Safe to call when absent.
      def delete(key)
        path = full_path(key)
        FileUtils.rm(path) if File.exist?(path)
      end

      # Returns the size in bytes of the stored file.
      def size(key)
        File.size(full_path(key))
      end

      # Returns the absolute filesystem path for key.
      # Used by send_file (Cycle 5) and make_temp_copy.
      def full_path(key)
        File.join(@base_path, key)
      end

      private

      CHUNK_SIZE = 10 ** 6 # 1 MB — mirrors ContentBlob::CHUNK_SIZE
    end
  end
end
