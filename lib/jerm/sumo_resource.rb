module Jerm
  class SumoResource < Resource
    
    attr_accessor :work_package, :experimenters
    
    def populate
      
    end

    def initialize
      self.project = "SUMO"
    end
  end
end