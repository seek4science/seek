require 'hpricot'

module Seek
  
  class JWSModelBuilder
    
    BASE_URL = "http://jjj.mib.ac.uk/webMathematica/Examples/"    
    SIMULATE_URL = "http://jjj.mib.ac.uk/webMathematica/upload/uploadNEW.jsp"    
    
    def builder_url
      "#{BASE_URL}JWSconstructor_panels/DatFileReader.jsp"
    end
    
    def upload_dat_url
      self.builder_url+"?datFilePosted=true"
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
      
      part=Multipart.new({:uploadedDatFile=>filepath})
      
      response = part.post(upload_dat_url)
      
      if response.instance_of?(Net::HTTPInternalServerError)       
        puts response.to_s
        raise Exception.new(response.body.gsub(/<head\>.*<\/head>/,""))
      end
      
      process_response_body(response.body)
      
    end
    
    def simulate saved_file
      url=simulate_url
      url=url+"?savedfile=#{saved_file}&inputFileConstructor=true"           
      
      part=Multipart.new({})
      
      response = part.post(url)
      
      if response.instance_of?(Net::HTTPInternalServerError)       
        puts response.to_s
        raise Exception.new(response.body.gsub(/<head\>.*<\/head>/,""))
      end
      
      if response.instance_of?(Net::HTTPRedirection)
        puts "REDIRECTION TO #{response['location']}"
      end
      
      extract_applet(response.body)
    end
    
    def extract_applet body
      doc = Hpricot(body)
      puts body
      element = doc.search("//object").first
      element.inner_html
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
        puts "OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO"
        puts obj.to_s
        puts "OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO"
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