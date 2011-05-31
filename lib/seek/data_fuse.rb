require 'rest_client'
require 'libxml'

module Seek
  module DataFuse

    MOCKED_RESPONSE=false

    class DataFuseResult
      attr_accessor :graph_url,:csv_url,:id,:name
    end

    def data_fuse_url
      "#{Seek::JWS::SIMULATE_URL}"
    end

    def submit_parameter_values_to_jws_online model,matching_keys,parameter_values_csv

        return process_data_fuse_response(dummy_data_fuse_response_xml) if MOCKED_RESPONSE

        filepath=model.content_blob.filepath

        #this is necessary to get the correct filename and especially extension, which JWS relies on
        tmpfile = Tempfile.new(model.original_filename)
        FileUtils.cp(filepath, tmpfile.path)

          part=Multipart.new("upfile", filepath, model.original_filename)
          url=URI.encode(data_fuse_url+"?parametercsv=#{parameter_values_csv}&matchingsymbols=#{matching_keys}")
          response = part.post(url)
          if response.code == "302"
            uri = URI.parse(URI.encode(response['location']))
            req = Net::HTTP::Get.new(uri.request_uri)
            response = Net::HTTP.start(uri.host, uri.port) { |http|
              http.request(req)
            }
          elsif response.code == "404"
            raise Exception.new("Page not found on JWS Online for url: #{upload_sbml_url}")
          elsif response.code == "500"
            raise Exception.new("Server error on JWS Online for url: #{upload_sbml_url}")
          else
            raise Exception.new("Expected a redirection from JWS Online but got #{response.code}, for url: #{upload_sbml_url}")
          end


        if response.instance_of?(Net::HTTPInternalServerError)
          raise Exception.new(response.body.gsub(/<head\>.*<\/head>/, ""))
        end

        process_data_fuse_response(response.body)

    end

    def process_data_fuse_response response
      parser = LibXML::XML::Parser.string(response, :encoding => LibXML::XML::Encoding::UTF_8)
      doc = parser.parse
      doc.find("//data_fuse_results/result").collect do |node|
        r=DataFuseResult.new
        r.name = node.attributes["name"]
        r.id = node.attributes["name"]
        r.graph_url = node.find_first("graph_url").content.strip unless node.find_first("graph_url").nil?
        r.csv_url = node.find_first("csv_url").content.strip unless node.find_first("csv_url").nil?
        r
      end

    end

    #only used for testing and development purposes
    def dummy_data_fuse_response_xml
      path="#{RAILS_ROOT}/test/data_fuse_example.xml"
      File.open(path, "rb").read
    end

  end
end