module Seek
  module JWS
    module MockedResponses

      def process_mocked_response
        body = read_mocked_xml "example_jws_response.xml"
        process_response_body body
      end

      def process_mocked_annotator_response
        body = read_mocked_xml "annotator_jws_response.xml"
        process_response_body body
      end

      def read_mocked_xml filename
        path="#{RAILS_ROOT}/test/#{filename}"
        File.open(path,"rb").read
      end

    end
  end
end
