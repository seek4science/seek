require 'uuidtools'
module Seek
  module Jws
    # methods related to interacting with JWS
    module Interaction
      # uploads the model, and returns the "slug", which is the identifier used to construct URLS to interact wit the model
      def upload_model_blob(blob)
        blob.with_temporary_copy do |temp_path|
          payload = upload_payload(temp_path)
          url = get_endpoint[get_upload_path].post(payload, cookie_header_definition) do |response, request, result, &block|
            if response.code == 302
              response.headers[:location]
            else
              response.return!(request, result, &block)
            end
          end
          extract_slug_from_url(url)
        end
      end

      def model_simulate_url_from_slug(slug)
        uri = URI.join(Seek::Config.jws_online_root, '/models/', slug + '/', 'simulate')
        uri.query="embedded=1"
        uri.to_s
      end

      def upload_payload(filepath)
        { model_file: File.new(filepath, 'rb') }
      end

      def cookie_header_definition
        token = determine_csrf_token
        { :cookies => { 'csrftoken' => token },
          'X-CSRFToken' => token,
          referer:Seek::Config.jws_online_root
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
