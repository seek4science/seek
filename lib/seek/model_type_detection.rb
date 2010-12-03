module Seek
  module ModelTypeDetection
    
    def is_dat? model      
      return false if !model.original_filename.end_with?(".dat")
      check_content model.content_blob.filepath,"begin name",25000
    end                      
    
    def is_sbml? model            
      return false if !model.original_filename.end_with?(".xml")      
      check_content model.content_blob.filepath,"<sbml"
    end
    
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