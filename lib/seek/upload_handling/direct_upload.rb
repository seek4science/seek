module Seek
  module UploadHandling
    # Hands a browser a short-lived, signed URL so it can upload a file straight into the storage
    # backend's staging area, bypassing SEEK. Only available on the S3 backend. The staged object is
    # turned into a ContentBlob later, when the asset form is submitted with the returned key.
    module DirectUpload
      include Seek::UploadHandling::ContentInspection

      DIRECT_UPLOAD_EXPIRY = 15.minutes

      # POST /content_blobs/direct_upload  params: filename, content_type (optional), size
      # Responds with JSON: strategy, key, url, expires_in, and the headers the PUT must send.
      def direct_upload
        refusal = direct_upload_refusal
        return render json: { error: refusal[:error] }, status: refusal[:status] if refusal

        content_type = params[:content_type].presence || content_type_from_filename(params[:filename].to_s)
        render json: direct_upload_ticket(content_type)
      end

      private

      # The same gates the normal upload form applies, checked before any URL is signed.
      # Returns nil when the request may proceed.
      def direct_upload_refusal
        if !Seek::Storage.direct_upload_enabled?
          { status: :not_found, error: 'Direct upload is not available on this instance.' }
        elsif !(User.logged_in_and_member? || User.admin_logged_in?)
          { status: :forbidden, error: "Only members of #{t('project').downcase.pluralize} can upload content." }
        elsif Seek::Config.block_file_uploads
          { status: :forbidden, error: 'Data upload is not allowed. Please provide a URL to the data instead.' }
        elsif params[:size].to_i <= 0
          { status: :unprocessable_entity, error: 'The file that you are uploading is empty.' }
        end
      end

      # A fresh staging key and a signed PUT URL for it. One ticket is valid for exactly one object and
      # one content type, so the browser asks for a new one per file.
      def direct_upload_ticket(content_type)
        key = SecureRandom.uuid
        expires_in = DIRECT_UPLOAD_EXPIRY.to_i
        url = Seek::Storage.upload_adapter.presigned_upload_url(key, content_type: content_type, expires_in: expires_in)
        { strategy: 'put', key: key, url: url, expires_in: expires_in, headers: { 'Content-Type' => content_type } }
      end
    end
  end
end
