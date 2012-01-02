require 'hpricot'
require 'rest_client'
require 'libxml'

module Seek
  module JWS

    BASE_URL = "#{Seek::Config.jws_online_root}/webMathematica/Examples/"
    UPLOAD_URL = "#{Seek::Config.jws_online_root}/webMathematica/upload/uploadNEW.jsp"

    class Builder

      include Seek::ModelTypeDetection
      include APIHandling

      def saved_dat_download_url savedfile
        "#{Seek::JWS::BASE_URL}JWSconstructor_panels/#{savedfile}"
      end

      def construct params
        required_params=jws_post_parameters
        url = builder_url
        form_data = {}
        required_params.each do |p|
          form_data[p]=params[p] if params.has_key?(p)
        end

        response = Net::HTTP.post_form(URI.parse(url), form_data)

        if response.instance_of?(Net::HTTPInternalServerError)
          raise Exception.new(response.body.gsub(/<head\>.*<\/head>/, ""))
        end

        process_response_body(response.body)
      end

      def builder_content model
          filepath=model.content_blob.filepath

          #this is necessary to get the correct filename and especially extension, which JWS relies on
          tmpfile = Tempfile.new(model.original_filename)
          FileUtils.cp(filepath, tmpfile.path)

          if (is_sbml? model)
            part=Multipart.new("upfile", filepath, model.original_filename)
            response = part.post(upload_sbml_url)
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
          elsif (is_dat? model)
            response = RestClient.post(upload_dat_url, :uploadedDatFile=>tmpfile, :filename=>model.original_filename, :multipart=>true) { |response, request, result, &block |
            if [301, 302, 307].include? response.code
              response.follow_redirection(request, result, &block)
            else
              response.return!(request, result, &block)
            end
            }
          end

          if response.instance_of?(Net::HTTPInternalServerError)
            raise Exception.new(response.body.gsub(/<head\>.*<\/head>/, ""))
          end

          process_response_body(response.body)
      end

      def sbml_download_url savedfile
        modelname=savedfile.gsub("\.dat", "")
        url=""
        response = RestClient.post(dat_to_sbml_url, :modelName=>modelname) do |response, request, result,
          &block |
          if [301, 302, 307].include? response.code
            url=response.headers[:location]
          else
            raise Exception.new("Redirection expected to converted dat file")
          end
        end
        url
      end

      private

      def dat_to_sbml_url
        "#{Seek::JWS::BASE_URL}JWSconstructor_panels/datToSBMLstageII.jsp"
      end

      def builder_url
        "#{Seek::JWS::BASE_URL}JWSconstructor_panels/DatFileReader_xml.jsp"
      end

      def upload_dat_url
        builder_url+"?datFilePosted=true"
      end

      def upload_sbml_url
        "#{Seek::JWS::UPLOAD_URL}?SBMLFilePostedToIFC=true&xmlOutput=true"
      end

      def saved_file_builder_content saved_file
        model_name=saved_file.gsub("\.dat", "")
        response = RestClient.get(builder_url, :params=>{:loadModel=>model_name, :userModel=>true})

        if response.instance_of?(Net::HTTPInternalServerError)
          raise Exception.new(response.body.gsub(/<head\>.*<\/head>/, ""))
        end
        process_response_body(response.body)
      end

    end
  end
end


