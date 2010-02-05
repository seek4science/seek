# To change this template, choose Tools | Templates
# and open the template in the editor.

module Jerm
  class Populator

    MESSAGES={:exists=>"Already exists.",
      :no_project=>"Unable to determine SEEK project.",
      :no_uri=>"Location of resource missing.",
      :no_author=>"Unable to determine the SEEK person for the author.",
      :no_default_policy=>"Unable to determine the default policy for this project.",
      :no_title=>"Unable to correctly determine the title",
      :success=>"Successfully added."
    }

    RESPONSE_CODES={:exists=>1,
      :no_project=>2,
      :no_uri=>3,
      :no_author=>4,
      :no_default_policy=>5,
      :no_title=>6,
      :success=>0
    }

    #adds a resource to the central SEEK archive, referenced by the remote URI, or creates new version if already exists.
    #returns a report:
    # {:response=>:success|:fail|:skipped,:message=>"",:exception=>Exception|nil,:resource=>resource}
    def populate resource
      resource.populate
      if !exists?(resource)
        response=add_as_new(resource)
      else
        response={:response=>:skipped,:message=>MESSAGES[:exists],:response_code=>RESPONSE_CODES[:exists]}
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
