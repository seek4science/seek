module Seek
  class AbstractSearchAdaptor
    attr_reader :yaml_config
    def initialize yaml_config
      @yaml_config = yaml_config
    end

    def search query
      raise NoMethodError.new("Abstract method, not yet implemented")
    end
  end
end
