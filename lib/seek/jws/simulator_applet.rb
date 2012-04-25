require 'hpricot'

module Seek
  module JWS
    class SimulatorApplet

      UPLOAD_URL = "#{Seek::Config.jws_online_root}/webMathematica/upload/uploadNEW.jsp"

      #takes either a Model instance (or Model::Version), or a Hash of params, and returns the applet object element,and the saved file name stored on JWS Online
      def simulate model_or_file

        @@builder ||= Seek::JWS::Builder.new

        if (model_or_file.is_a?(String))
          saved_file = model_or_file
        else
          params_hash,attribution_annotations,saved_file,objects_hash,error_keys = @@builder.builder_content model_or_file
        end

        url=upload_url
        response = RestClient.post(url, :savedfile=>saved_file, :multipart=>true) { |response, request, result, &block |
        if [301, 302, 307].include? response.code
          response.follow_redirection(request, result, &block)
        else
          response.return!(request, result, &block)
        end
        }
        extract_applet(response.body)
      end

      private

      def upload_url
        return UPLOAD_URL
      end

      def extract_applet body
        doc = Hpricot(body)
        element = doc.search("//object").first
        element.at("param").before(%!<param name="codebase" value="#{BASE_URL}"/>!)
        element.to_s
      end

    end
  end
end
