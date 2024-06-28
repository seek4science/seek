module Seek
  module Copasi
    module Simulator
      extend ActiveSupport::Concern

      included do
        before_action :find_model, :find_display_asset_for_copasi, :select_model_file_for_simulation, only: [:copasi_simulate]
        before_action :fetch_special_auth_code, if: -> { is_special_auth_code_required? }, only: [:copasi_simulate]

      end

      def copasi_simulate
        render 'copasi_simulate'
      end

      def find_model
        @model = Model.find_by_id(params[:id])
      end

      # # If the content blob is not available locally, fetch a copy from the remote URL
      def select_model_file_for_simulation

        @blob = nil

        content_blob = select_copasi_content_blob

        if content_blob.file_exists?
          @blob = (File.read(content_blob.file)).html_safe
        else
          blob_url = content_blob.url
          begin
            handler = ContentBlob.remote_content_handler_for(blob_url)
            data = handler.fetch
            @blob = (File.read(data)).html_safe
            true
          rescue Seek::DownloadHandling::BadResponseCodeException => e
            flash.now[:error] = "URL could not be accessed: #{e.message}"
            false
          rescue StandardError => e
            flash.now[:error] = 'There is a problem to load the model file.'
            false
          end
        end

        if @blob.nil?
          flash.now[:error] = 'There is a problem to load the model file.'
        end
      end

      # select the first COPASI-compatible content_blob when multiple items are associated with the display model.
      def select_copasi_content_blob
        blob = @display_model.copasi_supported_content_blobs.first
        raise 'Unable to find file to support Copasi Online' unless blob
        blob
      end

      def find_display_asset_for_copasi
        find_display_asset
      end


      # fetches or generates a special auth code with a "copasi_" prefix, which is used by COPASI desk application to load the non public model 
      def fetch_special_auth_code
        copasi_codes = special_auth_codes_with_copasi_prefix

        if copasi_codes.empty?
          # Generate a special auth code for a day
          auth_code = SpecialAuthCode.new(expiration_date: Time.now + 1.day)
          auth_code.update(code: "copasi_#{auth_code.code}")
          @model.special_auth_codes << auth_code
          auth_code # Ensure the new auth code is returned
        else
          copasi_codes.first
        end
      end

      private

      def special_auth_codes_with_copasi_prefix
        @model.special_auth_codes.where('code LIKE ?', 'copasi_%')
      end

      def is_special_auth_code_required?
        # If the model is not publicly accessible but can be downloaded by the current user, the special auth code will be required.
        Seek::Config.copasi_enabled && @display_model.is_copasi_supported? && @model.can_download? && !@model.public?
      end

    end
  end
end

