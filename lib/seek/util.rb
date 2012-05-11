module Seek
  module Util

    # This method removes the special Rails parameters from a params hash provided.   
    #
    # NOTE: the provided params collection will not be affected. 
    # Instead, a new hash will be returned. 
    def self.remove_rails_special_params_from(params, additional_to_remove=[])
      return {} if params.blank?

      special_params = %w( id format controller action commit ).concat(additional_to_remove)
      return params.reject { |k, v| special_params.include?(k.to_s.downcase) }
    end

    def self.ensure_models_loaded
      @@models_loaded ||= begin
        Dir.glob(RAILS_ROOT + '/app/models/*.rb').each do |file|
          model_name = file.gsub(".rb", "").split(File::SEPARATOR).last
          model_name.camelize.constantize
        end
        true
      end
    end

    def self.persistent_classes
      @@persistent_classes ||= begin
        ensure_models_loaded
        Object.subclasses_of(ActiveRecord::Base)
      end
    end

    #List of activerecord model classes that are directly creatable by a standard user (e.g. uploading a new DataFile, creating a new Assay, but NOT creating a new Project)
    #returns a list of all types that respond_to and return true for user_creatable?
    def self.user_creatable_types
      @@creatable_model_classes ||= begin
        classes=persistent_classes.select do |c|
          c.respond_to?("user_creatable?") && c.user_creatable?
        end.sort_by { |a| [a.is_asset? ? -1 : 1, a.is_isa? ? -1 : 1, a.name] }
        classes.delete(Event) unless Seek::Config.events_enabled
        classes.delete(Specimen)
        classes
      end
    end

    def self.authorized_types
      @@policy_authorised_types ||= begin
        persistent_classes.select do |c|
          c.respond_to?(:authorization_supported?) && c.authorization_supported?
        end.sort_by(&:name)
      end
    end

    def self.searchable_types
      @@searchable_types ||= begin
        persistent_classes.select do |c|
          c.respond_to?(:searchable?) && c.searchable?
        end.sort_by(&:name)
      end

    end

  end
end