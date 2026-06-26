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
      def initialize(bucket:, prefix:, **s3_options)
        @bucket = bucket
        @prefix = prefix
        @client = build_client(s3_options)
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

      # Streams the object's content in chunks, yielding each to the block, without buffering the
      # whole object in memory. Used to serve a download through the app (HTTP 200 + body) for clients
      # that cannot follow a presigned redirect (e.g. the COPASI/Morpheus desktop apps).
      def stream(key)
        @client.get_object(bucket: @bucket, key: object_key(key)) do |chunk, _headers|
          yield chunk
        end
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

      # Performs a read-only connectivity check against the configured bucket.
      # Returns { success: true/false, message: String }.
      # Never raises — all errors are captured in the returned hash.
      def test_connection
        @client.list_objects_v2(bucket: @bucket, max_keys: 1)
        { success: true, message: "Successfully connected to bucket '#{@bucket}'" }
      rescue Aws::S3::Errors::NoSuchBucket
        { success: false, message: "Bucket '#{@bucket}' does not exist" }
      rescue Aws::S3::Errors::AccessDenied, Aws::S3::Errors::InvalidAccessKeyId
        { success: false, message: "Access denied to bucket '#{@bucket}'. Check access_key_id and secret_access_key." }
      rescue Aws::S3::Errors::ServiceError => e
        { success: false, message: "S3 service error: #{e.message}" }
      rescue SocketError, Errno::ECONNREFUSED => e
        { success: false, message: "Cannot connect to S3 endpoint: #{e.message}" }
      end

      # Returns a presigned GET URL for the object, valid for expires_in seconds.
      # Objects are stored under an opaque "<uuid>.dat" key, so the URL must tell
      # S3 which filename and content type to return — otherwise the browser
      # saves the download as "<uuid>.dat" with a generic type and cannot open it.
      # These are applied via the response-content-disposition / response-content-type
      # response header overrides supported by S3 presigned GETs.
      def presigned_url(key, expires_in: 300, filename: nil, content_type: nil, disposition: 'attachment')
        presigner = Aws::S3::Presigner.new(client: @client)
        params = {
          bucket: @bucket,
          key: object_key(key),
          expires_in: expires_in
        }
        if filename.present?
          params[:response_content_disposition] =
            ActionDispatch::Http::ContentDisposition.format(disposition: disposition, filename: filename)
        end
        params[:response_content_type] = content_type if content_type.present?
        presigner.presigned_url(:get_object, **params)
      end

      private

      def build_client(opts)
        Aws::S3::Client.new(
          region: opts.fetch(:region, 'us-east-1'),
          access_key_id: opts[:access_key_id],
          secret_access_key: opts[:secret_access_key],
          endpoint: opts[:endpoint],
          force_path_style: opts.fetch(:force_path_style, false)
        )
      end

      def object_key(key)
        "#{@prefix}/#{key}"
      end
    end
  end
end
