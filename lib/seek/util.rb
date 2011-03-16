module Seek
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

    @@models_loaded = false
    def self.ensure_models_loaded
      unless @@models_loaded
        Dir.glob(RAILS_ROOT + '/app/models/*.rb').each do |file|
          model_name = file.gsub(".rb","").split(File::SEPARATOR).last
          model_name.camelize.constantize
        end
        @@models_loaded=true
      end
    end

    def self.persistent_classes
      @@persistent_classes ||= begin
        ensure_models_loaded
        Object.subclasses_of(ActiveRecord::Base)
      end
    end
    
  end
end