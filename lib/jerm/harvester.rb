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
    end
    
    def update      
      items = changed_since(last_run)
      resources = []
      items.each do |item|
        resource = construct_resource(item)
        resource.populate
        resources << resource
      end
      return resources
    end

    def last_run
      DateTime.parse("1 Jan 2007")
    end    

  end
end