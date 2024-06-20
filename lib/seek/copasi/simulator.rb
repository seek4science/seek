module Seek
  module Copasi
    module Simulator
      extend ActiveSupport::Concern

      included do
        before_action :find_display_asset_for_copasi, :find_model_file, only: [:copasi_simulate]
      end

      def copasi_simulate
        @model = Model.find_by_id(params[:id])
        @content_blob =  @model.content_blobs.first
        render 'copasi_simulate'
      end

      def find_model_file

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

      def select_copasi_content_blob
        blob = @display_model.copasi_supported_content_blobs.first
        raise 'Unable to find file to support Copasi Online' unless blob
        blob
      end

      def find_display_asset_for_copasi
        find_display_asset Model.find_by_id(params[:id])
      end

    end
  end
end

