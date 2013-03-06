module Seek
  class AbstractSearchAdaptor
    attr_reader :yaml_config, :partial_path, :name, :search_type
    def initialize yaml_config
      @yaml_config = yaml_config
      @partial_path = @yaml_config["partial_path"]
      @enabled = @yaml_config["enabled"]
      @name = @yaml_config["name"]
      @search_type = @yaml_config["search_type"]
    end

    def search query
      perform_search(query).each do |result|
        result.partial_path ||= partial_path
        result.tab ||= name
      end
    end

    def enabled?
      @enabled
    end


  end
end
