module Seek
  module JWS

    class Simulator

      UPLOAD_URL = "#{Seek::Config.jws_online_root}/webMathematica/model_upload_SEEK_xml.jsp"
      SIMULATE_BASE_URL = "#{Seek::Config.jws_online_root}/webMathematica/UItester.jsp"


      def simulate content_blob
        filepath=content_blob.filepath
        #this is necessary to get the correct filename and especially extension, which JWS relies on
        tmpfile = Tempfile.new([content_blob.original_filename,File.extname(content_blob.original_filename)])
        FileUtils.cp(filepath, tmpfile.path)
        response = RestClient.post(upload_url, :upfile=>tmpfile, :uploadModel=>true,:filename=>content_blob.original_filename, :multipart=>true) { |response, request, result, &block |
        if [301, 302, 307].include? response.code
          response.follow_redirection(request, result, &block)
        else
          response.return!(request, result, &block)
        end
        }
        extract_modelname_from_response(response.strip)
      end

      private

      def upload_url
        return Seek::JWS::Simulator::UPLOAD_URL
      end

      def extract_modelname_from_response response
        parser = LibXML::XML::Parser.string(response, :encoding => LibXML::XML::Encoding::UTF_8)
        doc = parser.parse
        name = doc.find_first("//uploader/modelname").content
        name.strip
      end

      def self.simulator_frame_url modelname
        "#{SIMULATE_BASE_URL}?fileName=#{modelname}&noHeader=true"
      end

    end
  end
end