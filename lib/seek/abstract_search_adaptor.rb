module Seek
  class AbstractSearchAdaptor
    attr_reader :yaml_config, :partial_path
    def initialize yaml_config
      @yaml_config = yaml_config
      @partial_path = @yaml_config["partial_path"]
    end

    def search query
      perform_search(query).each do |result|
        result.partial_path = partial_path
      end
    end
  end
end
