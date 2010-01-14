# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'jerm/embedded_populator'

module Jerm
  class Harvester
  
    attr_reader :base_uri

    def initialize(root_uri,user, pass)
      @username = user
      @password = pass

      #FIXME: fix inconsitency between root_uri, and base_uri
      @base_uri=root_uri

      #FIXME: populator type needs to be configurable, and not even sure it belongs here but perhaps better external to the Harvester.
      @populator=EmbeddedPopulator.new
    end
    
    def update
      responses=[]
      items = changed_since(last_run)
      resources = []
      items.each do |item|
        resource = construct_resource(item)
        responses << populate(resource)        
      end
      return responses
    end

    def last_run
      DateTime.parse("1 Jan 2007")
    end

    def populate resource
      return @populator.populate resource
    end

  end
end