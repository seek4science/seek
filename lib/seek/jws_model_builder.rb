require 'hpricot'
require 'rest_client'
require 'libxml'

module Seek
  
  class JWSModelBuilder
    
    include ModelTypeDetection
    
    BASE_URL = "http://130.88.195.31/webMathematica/Examples/"    
    SIMULATE_URL = "http://130.88.195.31/webMathematica/upload/uploadNEW.jsp"    
    
    def is_supported? model      
      model.content_blob.file_exists? && (is_sbml?(model) || is_dat?(model))  
    end
        
    def dat_to_sbml_url
      "#{BASE_URL}JWSconstructor_panels/datToSBMLstageII.jsp"
    end
    
    def saved_dat_download_url savedfile
        "#{BASE_URL}JWSconstructor_panels/#{savedfile}"
    end
    
    def builder_url
      "#{BASE_URL}JWSconstructor_panels/DatFileReader_xml.jsp"
    end
    
    def upload_dat_url
      builder_url+"?datFilePosted=true"
    end
    
    def upload_sbml_url
      "#{SIMULATE_URL}?SBMLFilePostedToIFC=true&xmlOutput=true"
    end
    
    def simulate_url
      SIMULATE_URL
    end
    
    def sbml_download_url savedfile
      modelname=savedfile.gsub("\.dat","")
      url=""
      response = RestClient.post(dat_to_sbml_url,:modelName=>modelname) do |response, request, result, &block|
        if [301, 302, 307].include? response.code
          url=response.headers[:location]        
        else
          raise Exception.new("Redirection expected to converted dat file")
        end
      end      
      url
    end
    
    def construct model,params
      
      required_params=["assignmentRules","modelname","parameterset","kinetics","functions","initVal","reaction","events","steadystateanalysis","plotGraphPanel","plotKineticsPanel"]
      url = builder_url
      form_data = {}
      required_params.each do |p|
        form_data[p]=params[p] if params.has_key?(p)
      end      
      
      puts "============ Plot graph - #{form_data['plotGraphPanel']}"
      response = Net::HTTP.post_form(URI.parse(url),form_data)
      
      if response.instance_of?(Net::HTTPInternalServerError)       
        puts response.to_s
        raise Exception.new(response.body.gsub(/<head\>.*<\/head>/,""))
      end
      
      puts "###########################################################"
      puts "Body = \n#{response.body}"
      puts "###########################################################"
      
      process_response_body(response.body)
    end
    
    def saved_file_builder_content saved_file
      model_name=saved_file.gsub("\.dat","")      
      response = RestClient.get(builder_url,:params=>{:loadModel=>model_name,:userModel=>true})
      
      puts response.body
      
      if response.instance_of?(Net::HTTPInternalServerError)       
        puts response.to_s
        raise Exception.new(response.body.gsub(/<head\>.*<\/head>/,""))
      end      
      process_response_body(response.body)
    end
    
    def builder_content model
            
      filepath=model.content_blob.filepath
      
      #this is necessary to get the correct filename and especially extension, which JWS relies on
      tmpfile = Tempfile.new(model.original_filename)       
      FileUtils.cp(filepath,tmpfile.path)
      
      if (is_sbml? model)        
        #        response = RestClient.post(upload_sbml_url,:upfile=>tmpfile.path,:multipart=>true) { |response, request, result, &block|
        #          if [301, 302, 307].include? response.code 
        #            puts "REDIRECT to #{response['location']}"
        #            response.follow_redirection(request, result, &block)
        #          else
        #            response.return!(request, result, &block)
        #          end
        #        }         
        part=Multipart.new("upfile",filepath,model.original_filename)
        response = part.post(upload_sbml_url)        
        if response.code == "302"
          uri = URI.parse(response['location'])          
          req = Net::HTTP::Get.new(uri.request_uri)
          response = Net::HTTP.start(uri.host, uri.port) {|http|
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
        response = RestClient.post(upload_dat_url,:uploadedDatFile=>tmpfile,:filename=>model.original_filename,:multipart=>true) { |response, request, result, &block|
          if [301, 302, 307].include? response.code
            response.follow_redirection(request, result, &block)
          else
            response.return!(request, result, &block)
          end
        }        
      end
      
      if response.instance_of?(Net::HTTPInternalServerError)       
        puts response.to_s
        raise Exception.new(response.body.gsub(/<head\>.*<\/head>/,""))
      end      
      #body = dummy_response_xml
      body = response.body
      puts "###########################################################"
      puts "Body = \n#{body}"
      puts "###########################################################"
      process_response_body(body)
      
    end
    
    def simulate saved_file
      url=simulate_url
      response = RestClient.post(url,:savedfile=>saved_file,:multipart=>true) { |response, request, result, &block|
        if [301, 302, 307].include? response.code          
          response.follow_redirection(request, result, &block)
        else
          response.return!(request, result, &block)
        end
      }
      
      extract_applet(response.body)      
    end
    
    def extract_applet body
      doc = Hpricot(body)      
      element = doc.search("//object").first
      element.at("param").before(%!<param name="codebase" value="#{BASE_URL}"/>!)      
      element.to_s
    end        
    
    def process_response_body body                              
      
      parser = LibXML::XML::Parser.string(body,:encoding => LibXML::XML::Encoding::UTF_8)
      doc = parser.parse
      param_values = extract_main_parameters doc      
        
      saved_file = determine_saved_file doc
      objects_hash = create_objects_hash doc     
      fields_with_errors = find_reported_errors doc
        
      #FIXME: temporary fix to as the builder validator always reports a problem with "functions"
      fields_with_errors.delete("functions")      
      return param_values,saved_file,objects_hash,fields_with_errors
    end
    
    def find_reported_errors doc
      errors=[]
      
      doc.find("//errorinfo/error").each do |error_report|
        value=error_report.content.strip
        name=error_report.attributes['id']        
        errors << name unless value=="0"
      end      
      
      return errors
    end
    
    def create_objects_hash doc
      objects_hash = {}
      doc.find("//form[@id='main']/objects/object").each do |node|
        id=node.attributes['id']        
        if ["reactionImage","kineticsImage"].include?(id)
          url=node.content.strip
          url = BASE_URL + "JWSconstructor_panels/" + url
          element_id = id =="reactionImage" ? "resizeableElement" : "resizeableElement2"
          objects_hash[id] = %!<object data="#{url}" id="#{element_id}" alt="Network structure" class="reContent"></object>!
        end
      end      
      objects_hash
    end
    
    def extract_main_parameters doc
      params={}
      doc.find("//form[@id='main']/*/parameter").each do |node|
        unless node.attributes['id'].nil?
          id=node.attributes['id']
          params[id]=node.content.strip
        end
      end     
      params
    end
    
    #OLD
    def create_data_script_hash doc
      keys=["events","functions","rules","parameters","initial","resizable_2","equations","resizable","reactions","modelname"]
      scripts = doc.search("//script[@type='text/javascript']").reverse
      keyi=0
      result={}
      scripts[0,keys.size].each do |script|
        k=keys[keyi]        
        result[k]=script.to_s
        keyi+=1
      end
      result      
    end
    
    def determine_saved_file doc
      file=nil
      node = doc.find_first("//form[@id='simulate']/parameters/parameter[@id='savedfile']")
      unless node.nil?
        file=node.content.strip
      end      
      file
    end        
    
    def dummy_response_xml
      path="#{RAILS_ROOT}/lib/seek/jws_example.xml"
      File.open(path,"rb").read
    end
      
  end
  
end