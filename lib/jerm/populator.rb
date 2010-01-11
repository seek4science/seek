# To change this template, choose Tools | Templates
# and open the template in the editor.

module Jerm
  class Populator

    #adds a resource to the central SEEK archive, referenced by the remote URI, or creates new version if already exists.
    def populate resource
      resource.populate
      
    end

  end
end
