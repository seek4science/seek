require 'aws-sdk-s3'

module Seek
  module Storage
    # S3Adapter stores files on any S3-compatible object store (AWS S3, MinIO, etc.).
    # It presents the same interface as LocalAdapter so callers are backend-agnostic.
    #
    # Objects are namespaced under a prefix supplied at construction time:
    #   assets/uuid.dat        (prefix: 'assets')
    #   converted/uuid.pdf     (prefix: 'converted')
    class S3Adapter
      def initialize(bucket:, prefix:, region: 'us-east-1',
                     access_key_id: nil, secret_access_key: nil,
                     endpoint: nil, force_path_style: false, **_rest)
        @bucket = bucket
        @prefix = prefix
        @client = Aws::S3::Client.new(
          region: region,
          access_key_id: access_key_id,
          secret_access_key: secret_access_key,
          endpoint: endpoint,
          force_path_style: force_path_style
        )
      end

      # Write String or IO content to S3 under the given key.
      def write(key, content)
        body = content.respond_to?(:read) ? content : StringIO.new(content.to_s)
        body.rewind if body.respond_to?(:rewind)
        @client.put_object(bucket: @bucket, key: object_key(key), body: body)
      end

      # Upload a local file at src_path to S3 under the given key.
      def copy_from_path(src_path, key)
        File.open(src_path, 'rb') do |f|
          @client.put_object(bucket: @bucket, key: object_key(key), body: f)
        end
      end

      # Returns a StringIO with the object's full content.
      # Wraps the SDK response body so callers receive a stable, predictable
      # readable object rather than an SDK-internal IO type.
      def open(key)
        response = @client.get_object(bucket: @bucket, key: object_key(key))
        StringIO.new(response.body.read)
      end

      # Returns true if the object exists. Handles multiple not-found error forms
      # raised by different SDK versions and S3-compatible servers.
      def exist?(key)
        @client.head_object(bucket: @bucket, key: object_key(key))
        true
      rescue Aws::S3::Errors::NotFound,
             Aws::S3::Errors::NoSuchKey,
             Aws::S3::Errors::Forbidden
        false
      rescue Aws::S3::Errors::ServiceError => e
        raise unless e.context.http_response.status_code == 404
        false
      end

      # Deletes the object. S3 delete is idempotent — safe to call when absent.
      def delete(key)
        @client.delete_object(bucket: @bucket, key: object_key(key))
      end

      # Returns the object size in bytes.
      def size(key)
        @client.head_object(bucket: @bucket, key: object_key(key)).content_length
      end

      # S3 has no local filesystem path. Returns nil.
      # Callers that need a local copy (e.g. make_temp_copy) must be updated
      # to use with_local_copy instead — that is handled in Cycle 6.
      def full_path(_key)
        nil
      end

      # Returns a presigned GET URL for the object, valid for expires_in seconds.
      def presigned_url(key, expires_in: 300)
        presigner = Aws::S3::Presigner.new(client: @client)
        presigner.presigned_url(:get_object,
                                bucket: @bucket,
                                key: object_key(key),
                                expires_in: expires_in)
      end

      private

      def object_key(key)
        "#{@prefix}/#{key}"
      end
    end
  end
end
