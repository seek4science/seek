require 'hpricot'
require 'rest_client'
require 'libxml'

module Seek
  module JWS

    BASE_URL = "#{Seek::Config.jws_online_root}/webMathematica/Examples/"
    SIMULATE_URL = "#{Seek::Config.jws_online_root}/webMathematica/upload/uploadNEW.jsp"

    class OneStop

      include Seek::ModelTypeDetection
      include Annotator
      include MockedResponses

      def is_supported? model
        model.content_blob.file_exists? && is_jws_supported?(model)
      end

      def saved_dat_download_url savedfile
        "#{Seek::JWS::BASE_URL}JWSconstructor_panels/#{savedfile}"
      end

      def construct params

        return process_mocked_response if Seek::JWS::MOCKED

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

          return process_mocked_response if Seek::JWS::MOCKED

          filepath=model.content_blob.filepath

          #this is necessary to get the correct filename and especially extension, which JWS relies on
          tmpfile = Tempfile.new(model.original_filename)
          FileUtils.cp(filepath, tmpfile.path)

          if (is_sbml? model)
            #        response = RestClient.post(upload_sbml_url,:upfile=>tmpfile.path,:multipart=>true) { |response, request, result, &block|
            #          if [301, 302, 307].include? response.code
            #            response.follow_redirection(request, result, &block)
            #          else
            #            response.return!(request, result, &block)
            #          end
            #        }
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

      def simulate saved_file
        url=Seek::JWS::SIMULATE_URL
        response = RestClient.post(url, :savedfile=>saved_file, :multipart=>true) { |response, request, result, &block |
        if [301, 302, 307].include? response.code
          response.follow_redirection(request, result, &block)
        else
          response.return!(request, result, &block)
        end
        }

        extract_applet(response.body)
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

      def jws_post_parameters
        ["nameToSearch", "urnsearchbox", "selectedSymbol", "urnsearchboxReaction", "selectedReactionSymbol", "assignmentRules", "annotationsReactions", "annotationsSpecies", "modelname", "parameterset", "kinetics", "functions", "initVal", "reaction", "events", "steadystateanalysis", "plotGraphPanel", "plotKineticsPanel","citationURL","citationURN","modelURN","creationTime","modificationTime","authors","TOD","notes"]
      end

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
        "#{Seek::JWS::SIMULATE_URL}?SBMLFilePostedToIFC=true&xmlOutput=true"
      end

      def saved_file_builder_content saved_file
        model_name=saved_file.gsub("\.dat", "")
        response = RestClient.get(builder_url, :params=>{:loadModel=>model_name, :userModel=>true})

        if response.instance_of?(Net::HTTPInternalServerError)
          raise Exception.new(response.body.gsub(/<head\>.*<\/head>/, ""))
        end
        process_response_body(response.body)
      end

      def extract_applet body
        doc = Hpricot(body)
        element = doc.search("//object").first
        element.at("param").before(%!<param name="codebase" value="#{BASE_URL}"/>!)
        element.to_s
      end

      def process_response_body body
        parser = LibXML::XML::Parser.string(body, :encoding => LibXML::XML::Encoding::UTF_8)
        doc = parser.parse
        param_values = extract_main_parameters doc

        saved_file = determine_saved_file doc
        objects_hash = create_objects_hash doc
        fields_with_errors = find_reported_errors doc
        attribution_annotations = find_attribution_annotations param_values

        return param_values, attribution_annotations, saved_file, objects_hash, fields_with_errors
      end

      def extract_main_parameters doc
        params={}
        doc.find("//form[@id='main']/*/parameter").each do |node|
          unless node.attributes['id'].nil?
            id=node.attributes['id']
            params[id]=node.content.strip
          end
        end

        #FIXME: this is only required until the parameters for attributions are moved to the parameters block
        doc.find("//form[@id='main']/parameter").each do |node|
          unless node.attributes['id'].nil?
            id=node.attributes['id']
            params[id]=node.content.strip
          end
        end

        params
      end

      def determine_saved_file doc
        file=nil
        node = doc.find_first("//form[@id='simulate']/parameters/parameter[@id='savedfile']")
        unless node.nil?
          file=node.content.strip
        end
        file
      end

      def find_reported_errors doc
        errors=[]

        doc.find("//errorinfo/error").each do |error_report|
          value=error_report.content.strip
          name=error_report.attributes['id']
          errors << name unless value=="0"
        end

        #FIXME: temporary fix to as the builder validator always reports a problem with "functions"
        errors.delete("functions")

        errors
      end

      def create_objects_hash doc
        objects_hash = {}
        doc.find("//form[@id='main']/objects/object").each do |node|
          id=node.attributes['id']
          if ["reactionImage", "kineticsImage"].include?(id)
            url=node.content.strip
            url = BASE_URL + "JWSconstructor_panels/" + url
            objects_hash[id]=url
            #objects_hash[id] = %!<object data="#{url}" id="#{element_id}" alt="Network structure" class="reContent"></object>!
          end
        end
        objects_hash
      end

    end
  end
end
