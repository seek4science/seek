module Seek
  # Provides access to the columns for the table view of the index page for a given resource
  class IndexTableColumnDefinitions
    # columns that must always be available
    def self.required_columns(resource)
      cache(resource, :reqiured) do
        columns = definition_for(resource, :required) | definitions[:general][:required]
        columns -= definition_for(resource, :blocked)
        check(columns, resource).uniq
      end
    end

    # optional columns that are shown by default
    def self.default_columns(resource)
      cache(resource, :default) do
        columns = definition_for(resource, :default) | definitions[:general][:default]
        columns -= definition_for(resource, :blocked)
        check(columns, resource).uniq
      end
    end

    # these are all the allowed columns, in order of required, default and then additional allowed columns
    def self.allowed_columns(resource)
      cache(resource, :allowed) do
        columns = required_columns(resource) | default_columns(resource)
        columns |= definition_for(resource, :additional_allowed) | definitions[:general][:additional_allowed]
        columns -= definition_for(resource, :blocked)
        check(columns, resource).uniq
      end
    end

    def self.cache(resource, category)
      @definition ||= {}
      @definition[resource.class.name] ||= {}
      return @definition[resource.class.name][category] unless @definition[resource.class.name][category].blank?

      @definition[resource.class.name][category] = yield
    end

    def self.definition_for(resource, category)
      return [] unless definitions[resource.model_name.name.underscore]

      definitions[resource.model_name.name.underscore][category] || []
    end

    def self.definitions
      @definitions ||= load_yaml
    end

    def self.load_yaml
      yaml = YAML.load_file(File.join(File.dirname(File.expand_path(__FILE__)), 'index_table_columns.yml'))
      HashWithIndifferentAccess.new(yaml)[:columns]
    end

    def self.check(cols, resource)
      cols.select do |col|
        resource.respond_to?(col)
      end
    end

    private_class_method :cache, :definition_for, :definitions, :load_yaml, :check
  end
end
