module Seek
  module Data
    # methods used for generating checksums, currently used by ContentBlob. Could be adapted to be reused by other file-based models
    module Checksums
      CHECKSUM_CHUNK_SIZE = 2 ** 20

      extend ActiveSupport::Concern

      included do
        before_save :calculate_checksums
      end

      def md5sum
        if super.nil?
          other_changes = self.changed?
          calculate_checksums # calculate all, since they are problably all needed
          # only save if there are no other changes - this is to avoid inadvertantly storing other potentially unwanted changes
          save unless other_changes
        end
        super
      end

      def sha1sum
        if super.nil?
          other_changes = self.changed?
          calculate_checksums
          # only save if there are no other changes - this is to avoid inadvertantly storing other potentially unwanted changes
          save unless other_changes
        end
        super
      end

      def calculate_checksums
        calculate_checksum :md5
        calculate_checksum :sha1
      end

      # calculate the checksum for the file, using the digest type, which could be :md5 or :sha1
      def calculate_checksum(digest_type)
        return unless shrine_file_stored?

        digest = "Digest::#{digest_type.upcase}".constantize.new

        file_attacher&.file&.open do |io|
          io.binmode if io.respond_to?(:binmode)
          while (chunk = io.read(CHECKSUM_CHUNK_SIZE))
            digest.update(chunk)
          end
        end

        send("#{digest_type}sum=", digest.hexdigest)
      end

      private

      def shrine_file_stored?
        respond_to?(:file_attacher) && file_attacher&.attached?
      end
    end
  end
end
