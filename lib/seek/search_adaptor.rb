module Seek
  class SearchAdaptor
    attr_reader :yaml_config
    def initialize yaml_config
      @yaml_config = yaml_config
    end

    def search query
      raise Exception.new("Not implemented")
    end
  end
end
