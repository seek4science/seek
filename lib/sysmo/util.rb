module Sysmo
  module Util
    
    # This method removes the special Rails parameters from a params hash provided.   
    #
    # NOTE: the provided params collection will not be affected. 
    # Instead, a new hash will be returned. 
    def self.remove_rails_special_params_from(params, additional_to_remove=[])
      return { } if params.blank?
      
      special_params = %w( id format controller action commit ).concat(additional_to_remove)
      return params.reject { |k,v| special_params.include?(k.to_s.downcase) }
    end
    
  end
end