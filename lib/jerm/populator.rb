# To change this template, choose Tools | Templates
# and open the template in the editor.

module Jerm
  class Populator    

    #adds a resource to the central SEEK archive, referenced by the remote URI, or creates new version if already exists.
    def populate resource
      resource.populate
      if !exists?(resource)
        add_as_new(resource)
      end
    end

    #checks whether the resource already exists in the registry
    def exists? resource
      !find_by_uri(resource.uri).nil?
    end

  end
end
