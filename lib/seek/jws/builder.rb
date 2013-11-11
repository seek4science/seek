require 'hpricot'
require 'rest_client'
require 'libxml'

module Seek
  module JWS

    BASE_URL = "#{Seek::Config.jws_online_root}/webMathematica/Examples/"
    UPLOAD_URL = "#{Seek::Config.jws_online_root}/webMathematica/upload/uploadSBML.jsp"

    class Builder

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

        response = RestClient.post(url, form_data)

        if response.instance_of?(Net::HTTPInternalServerError)
          raise Exception.new(response.body.gsub(/<head\>.*<\/head>/, ""))
        end

        process_response_body(response.body)
      end

      def builder_content content_blob
          filepath=content_blob.filepath

          #this is necessary to get the correct filename and especially extension, which JWS relies on
          tmpfile = Tempfile.new([content_blob.original_filename,File.extname(content_blob.original_filename)])
          FileUtils.cp(filepath, tmpfile.path)

          if (content_blob.is_sbml?)
            response = RestClient.post(upload_sbml_url, :upfile=>tmpfile,:SBMLFilePostedToIFC=>true, :xmloutput=>true,:loadModel=>content_blob.original_filename, :multipart=>true) do |response, request, result, &block |
              if [301, 302, 307].include? response.code
                response.follow_redirection(request, result, &block)
              else
                begin
                  response.return!(request, result, &block)
                rescue Exception=>e
                  raise Exception.new "Error contacting JWSOnline #{e.class.name}:#{e.message}. Code: #{response.code}\n\nCause: #{response.body}"
                end
              end
            end
          elsif (content_blob.is_jws_dat?)
            response = RestClient.post(upload_dat_url, :uploadedDatFile=>tmpfile, :filename=>content_blob.original_filename, :multipart=>true) do |response, request, result, &block |
              if [301, 302, 307].include? response.code
                response.follow_redirection(request, result, &block)
              else
                response.return!(request, result, &block)
              end
            end
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

      def saved_file_builder_content saved_file
        model_name=saved_file.gsub("\.dat", "")
        response = RestClient.get(builder_url, :params=>{:loadModel=>model_name, :userModel=>true})

        if response.instance_of?(Net::HTTPInternalServerError)
          raise Exception.new(response.body.gsub(/<head\>.*<\/head>/, ""))
        end
        process_response_body(response.body)
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
        Seek::JWS::UPLOAD_URL
      end

    end
  end
end


