# To change this template, choose Tools | Templates
# and open the template in the editor.

module Jerm
  class Populator

    MESSAGES={:exists=>"Already exists",:no_project=>"Unable to determine SEEK project",:no_uri=>"Location of resource missing",:no_author=>"Unable to determine the SEEK person for the author"}

    #adds a resource to the central SEEK archive, referenced by the remote URI, or creates new version if already exists.
    #returns a report:
    # {:response=>:success|:fail|:skipped,:message=>"",:exception=>Exception|nil,:resource=>resource}
    def populate resource
      resource.populate
      if !exists?(resource)
        response=add_as_new(resource)
      else
        response={:response=>:skipped,:message=>MESSAGES[:exists]}
      end
      response[:resource]=resource
      return response
    end

    #checks whether the resource already exists in the registry
    def exists? resource
      !find_by_uri(resource.uri).nil?
    end

  end
end
