module Seek
  class AbstractSearchAdaptor
    attr_reader :yaml_config, :partial_path, :name, :search_type, :key
    def initialize(yaml_config)
      @yaml_config = yaml_config
      @partial_path = @yaml_config['partial_path']
      @name = @yaml_config['name']
      @search_type = @yaml_config['search_type']
      @key = @yaml_config['key']
    end

    def search(query)
      perform_search(query).each do |result|
        result.partial_path ||= partial_path
        result.tab ||= name
      end
    end

    def get_item(item_id)
      item = fetch_item item_id
      item.partial_path ||= partial_path
      item.tab ||= name
      item
    end

    def enabled?
      settings = Seek::Config.external_search_adaptors || {}
      if settings.key?(key)
        settings[key]
      else
        true
      end
    end
  end
end
