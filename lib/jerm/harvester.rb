# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'jerm/embedded_populator'

module Jerm
  class Harvester
  
    attr_reader :base_uri

    def initialize(user, pass, populator)
      @username = user
      @password = pass

      @populator=populator
    end
    
    def update
      items = changed_since(last_run)
      resources = []
      items.each do |item|
        resource = construct_resource(item)
        populate resource
        resources << resource
      end
      return resources
    end

    def last_run
      DateTime.parse("1 Jan 2007")
    end

    def populate resource
      @populator.populate resource
    end

  end
end