module Seek
  class IndexTableColumnDefinitions

    def self.allowed_columns(resource)
      columns = required_columns(resource) | default_columns(resource) | definitions[:general][:additional_allowed] | (definitions[resource.model_name.name.underscore]&.fetch(:additional_allowed) || [])
      check(columns, resource)
    end

    def self.required_columns(resource)
      columns = definitions[:general][:required] | (definitions[resource.model_name.name.underscore]&.fetch(:required) || [])
      check(columns, resource)
    end

    def self.default_columns(resource)
      columns = definitions[:general][:default] | (definitions[resource.model_name.name.underscore]&.fetch(:default) || [])
      check(columns, resource)
    end

    private

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







  end
end