module Seek
  module Jws
    module Simulator
      extend ActiveSupport::Concern
      # include Seek::Jws::Interaction

      included do
        before_filter :find_display_asset_for_jws, only: [:simulate]
        before_filter :jws_enabled, only: [:simulate]
      end

      def simulate
        slug = upload_model_blob(select_jws_content_blob)
      end

      def select_jws_content_blob
        blob = @display_model.jws_supported_content_blobs.first
        fail 'Unable to find file to support JWS Online' unless blob
        blob
      end
    end

    module Interaction
      # uploads the model, and returns the "slug", which is the idenfier used to contruct URLS to interact wit the model
      def upload_model_blob(blob)
        url = get_endpoint[get_upload_path].post(upload_payload(blob.filepath), cookie_header_definition) do |response, request, result, &block|
          if response.code == 302
            response.headers[:location]
          else
            response.return!(request, result, &block)
          end
        end
        extract_slug_from_url(url)
      end

      def upload_payload(filepath)
        { model_file: File.new(filepath, 'rb') }
      end

      def cookie_header_definition
        token = determine_csrf_token
        { :cookies => { 'csrftoken' => token },
          'X-CSRFToken' => token,
        }
      end

      def extract_slug_from_url(url)
        URI.parse(url).path.split('/')[2]
      end

      def determine_csrf_token
        get_endpoint[get_upload_path].head.cookies['csrftoken']
      end

      def get_upload_path
        '/models/upload/'
      end

      def get_endpoint
        RestClient::Resource.new(Seek::Config.jws_online_root)
      end
    end
  end
end
