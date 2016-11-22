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

    def self.clear_cached
      self.class_variables.each do |v|
        self.class_variable_set(v,nil)
      end
    end

    def self.ensure_models_loaded
      @@models_loaded ||= begin
        Dir.glob("#{Rails.root}/app/models/**/*.rb").each do |file|
          model_name = file.gsub(".rb", "").gsub(File::SEPARATOR, '/').gsub("#{Rails.root}/app/models/",'')
          model_name.camelize.constantize
        end
        true
      end
    end

    def self.persistent_classes
      @@persistent_classes ||= begin
        ensure_models_loaded
        ActiveRecord::Base.descendants
      end
    end

    #List of activerecord model classes that are directly creatable by a standard user (e.g. uploading a new DataFile, creating a new Assay, but NOT creating a new Project)
    #returns a list of all types that respond_to and return true for user_creatable?
    def self.user_creatable_types
      #FIXME: the user_creatable? is a bit mis-leading since we now support creation of people, projects, programmes by certain people in certain roles.
      @@creatable_model_classes ||= begin
        persistent_classes.select do |c|
          c.respond_to?("user_creatable?") && c.user_creatable?
        end.sort_by { |a| [a.is_asset? ? -1 : 1, a.is_isa? ? -1 : 1, a.name] }
      end
    end


    def self.publishable_types
      authorized_types.select{|klass| klass.is_isa? || klass.first.try(:is_in_isa_publishable?) }
    end

    def self.authorized_types
      @@policy_authorised_types ||= begin
        persistent_classes.select do |c|
          c.respond_to?(:authorization_supported?) && c.authorization_supported?
        end.sort_by(&:name)
      end
    end

    def self.searchable_types
      #FIXME: hard-coded extra types - are are these items now user_creatable?
      #FIXME: remove the reliance on user-creatable, partly by respond_to?(:reindex) but also take into account if it has been enabled or not
      #- could add a searchable? method
      extras = [Person, Programme, Project, Institution]
      extras.delete(Programme) unless Seek::Config.programmes_enabled
      @@searchable_types ||= (user_creatable_types | extras).sort_by(&:name)
    end

    def self.scalable_types
      @@scalable_types ||= begin
        persistent_classes.select do |c|
          c.included_modules.include?(Seek::Scalable::InstanceMethods)
        end.sort_by(&:name)
      end
    end

    def self.rdf_capable_types
      @@rdf_capable_types ||= begin
        persistent_classes.select do |c|
          c.included_modules.include?(Seek::Rdf::RdfGeneration)
        end
      end
    end

    def self.breadcrumb_types
      @@breadcrumb_types ||= begin
        persistent_classes.select do |c|
          c.is_isa? || c.is_asset? || c.is_yellow_pages? || c.name == 'Event'
        end.sort_by(&:name)
      end
    end

    def self.asset_types
      @@asset_types ||= begin
        persistent_classes.select do |c|
          c.is_asset?
        end.sort_by(&:name)
      end
    end

    def self.inline_viewable_content_types
      #FIXME: needs to be discovered rather than hard-code classes here
      [DataFile, Model, Presentation, Sop]
    end

    def self.multi_files_asset_types
      asset_types.select do |c|
        c.instance_methods.include?(:content_blobs)
      end
    end

    def self.doiable_asset_types
      @@doiable_types ||= begin
        persistent_classes.select do |c|
          c.supports_doi?
        end.sort_by(&:name)
      end
    end
  end
end