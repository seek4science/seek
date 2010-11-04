require 'hpricot'
require 'rest_client'

module Seek
  
  class JWSModelBuilder
    
    BASE_URL = "http://jjj.mib.ac.uk/webMathematica/Examples/"    
    SIMULATE_URL = "http://jjj.mib.ac.uk/webMathematica/upload/uploadNEW.jsp"    
    
    def is_supported? model
      is_sbml?(model) || is_dat?(model)  
    end
    
    def is_dat? model
      #FIXME: needs to actually check contents rather than the extension
      model.original_filename.end_with?(".dat")
    end
    
    def get_saved_dat_url savedfile
        "#{BASE_URL}JWSconstructor_panels/#{savedfile}"
    end
    
    def is_sbml? model
      #FIXME: needs to actually check contents rather than the extension
      model.original_filename.end_with?(".xml")
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
      puts element.to_s
      element.to_s
    end        
    
    def process_response_body body                  
      
      doc = Hpricot(body)
      
      data_scripts = create_data_script_hash doc
      saved_file = determine_saved_file doc
      objects_hash = create_objects_hash doc
      
      
      return data_scripts,saved_file,objects_hash
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
        
        #        puts "-------- script for key: #{k} ----------"
        #        puts result[k]
        #        puts "----------------------------------------"
        
        keyi+=1
      end
      result      
    end
    
    def determine_saved_file doc
      element = doc.search("//input[@name='savedfile']").first
      return element.attributes['value']      
    end        
    
  end
  
end