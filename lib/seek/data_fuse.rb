require 'rest_client'
require 'libxml'

module Seek
  module DataFuse

    def data_fuse_url
      "#{Seek::JWSModelBuilder::BASE_URL}DataFuse.jsp"
    end

    def submit_parameter_values_to_jws_online model,matching_keys,parameter_values_csv
        filepath=model.content_blob.filepath

        #this is necessary to get the correct filename and especially extension, which JWS relies on
        tmpfile = Tempfile.new(model.original_filename)
        FileUtils.cp(filepath, tmpfile.path)

#          part=Multipart.new("upfile", filepath, model.original_filename)
#          response = part.post(data_fuse_url)
#          if response.code == "302"
#            uri = URI.parse(response['location'])
#            req = Net::HTTP::Get.new(uri.request_uri)
#            response = Net::HTTP.start(uri.host, uri.port) { |http|
#              http.request(req)
#            }
#          elsif response.code == "404"
#            raise Exception.new("Page not found on JWS Online for url: #{upload_sbml_url}")
#          elsif response.code == "500"
#            raise Exception.new("Server error on JWS Online for url: #{upload_sbml_url}")
#          else
#            raise Exception.new("Expected a redirection from JWS Online but got #{response.code}, for url: #{upload_sbml_url}")
#          end
          response = RestClient.post(data_fuse_url, :uploadedFile=>tmpfile,:parametercsv=>parameter_values_csv,:matchingsymbols=>matching_keys, :filename=>model.original_filename, :multipart=>true) { |response, request, result, &block |
          if [301, 302, 307].include? response.code
            response.follow_redirection(request, result, &block)
          else
            response.return!(request, result, &block)
          end
          }


        if response.instance_of?(Net::HTTPInternalServerError)
          raise Exception.new(response.body.gsub(/<head\>.*<\/head>/, ""))
        end

        #process_response_body(response.body)
        puts response.body

    end

  end
end