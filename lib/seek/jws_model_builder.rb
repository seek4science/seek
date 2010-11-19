require 'hpricot'
require 'rest_client'

module Seek
  
  class JWSModelBuilder
    
    include ModelTypeDetection
    
    BASE_URL = "http://jjj.mib.ac.uk/webMathematica/Examples/"    
    SIMULATE_URL = "http://jjj.mib.ac.uk/webMathematica/upload/uploadNEW.jsp"    
    
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
      "#{BASE_URL}JWSconstructor_panels/DatFileReader.jsp"
    end
    
    def upload_dat_url
      builder_url+"?datFilePosted=true"
    end
    
    def upload_sbml_url
      "#{SIMULATE_URL}?SBMLFilePostedToIFC=true"      
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
      
      response = Net::HTTP.post_form(URI.parse(url),form_data)
      
      if response.instance_of?(Net::HTTPInternalServerError)       
        puts response.to_s
        raise Exception.new(response.body.gsub(/<head\>.*<\/head>/,""))
      end
      
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
        else          
          raise Exception.new("Expected a redirection from JWS Online")
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
      process_response_body(response.body)
      
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
      
      doc = Hpricot(body)      
      data_scripts = create_data_script_hash doc
      saved_file = determine_saved_file doc
      objects_hash = create_objects_hash doc      
      fields_with_errors = find_reported_errors doc
        
      #FIXME: temporary fix to as the builder validator always reports a problem with "functions"
      fields_with_errors.delete("functions")      
      return data_scripts,saved_file,objects_hash,fields_with_errors
    end
    
    def find_reported_errors doc
      errors=[]
      doc.search("//form[@name='errorinfo']/input").each do |error_report|
        value=error_report.attributes['value']
        name=error_report.attributes['name']
        name=name.gsub("Errors","")
        errors << name unless value=="0"
      end      
      return errors
    end
    
    def create_objects_hash doc
      result = {}
      doc.search("//object").each do |obj|
        id=obj.attributes['id']
        obj.attributes['data']=BASE_URL+"/"+obj.attributes['data']
        result[id]=obj.to_s        
      end
      return result
    end
    
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
      elements = doc.search("//input[@name='savedfile']")      
      element = elements.first
      return element.attributes['value']      
    end        
    
  end
  
end