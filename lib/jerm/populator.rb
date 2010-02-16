# To change this template, choose Tools | Templates
# and open the template in the editor.
require 'digest/md5'

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

      exists = false
      
      #Check the URI doesn't exist
      if find_by_uri(resource.uri).nil?
        #Check the file doesn't exist
        #FIXME: Checks project here and again in the embeddedpopulator later on.
        project = Project.find(:first,:conditions=>['name = ?',resource.project]) #get project
        if project.nil?
          return false
        end
        project.decrypt_credentials
        downloader = DownloaderFactory.create resource.project
        file = downloader.get_remote_data(resource.uri,project.site_username,project.site_password)
        unless file.nil?
          digest = Digest::MD5.new
          digest << file[:data]
          md5sum = digest.hexdigest
          exists = !ContentBlob.find(:first,:conditions=>{:md5sum=>md5sum}).nil?
        else
          return false
        end
      else
        exists = true
      end
      
      return exists
    end

  end
end
