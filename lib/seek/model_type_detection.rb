module Seek
  #Detectes the type of the model based on the content, and determines whether it is SBML or JWS Dat format.
  #methods either take a model or content_blob, or can be mixed in with a Model entity.
  #It doesn't test whether the SBML is valid at this time.
  module ModelTypeDetection
    
    def is_dat? model_or_blob=self
      content_blob = model_or_blob.is_a?(ContentBlob) ?  model_or_blob : model_or_blob.content_blob
      content_blob.file_exists? && check_content(content_blob.filepath,"begin name",25000)
    end                      
    
    def is_sbml? model_or_blob=self
      content_blob = model_or_blob.is_a?(ContentBlob) ?  model_or_blob : model_or_blob.content_blob
      content_blob.file_exists? && (check_content content_blob.filepath,"<sbml")
    end

    def is_jws_supported? model_or_blob=self
      is_dat?(model_or_blob) || is_sbml?(model_or_blob)
    end

    private
    
    def check_content filepath, str, max_length=1500      
      char_count=0      
      begin
        f = File.open(filepath, "r") 
        f.each_line do |line|
          char_count += line.length
          return true  if line.downcase.include?(str)
          break if char_count>=max_length        
        end 
      rescue
    end
    
      false
    end
    
  end
end