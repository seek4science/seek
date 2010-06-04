require 'digest/md5'
require 'uuidtools'

module Jerm
  class Populator

    MESSAGES={:exists=>"Already exists.",
      :no_project=>"Unable to determine SEEK project.",
      :no_uri=>"Location of resource missing.",
      :no_author=>"Unable to determine the SEEK person for the author.",
      :no_default_policy=>"Unable to determine the default policy for this project.",
      :no_title=>"Unable to correctly determine the title",
      :unknown_auth=>"The authorization policy was not recognised",
      :success=>"Successfully added."
    }

    RESPONSE_CODES={:exists=>1,
      :no_project=>2,
      :no_uri=>3,
      :no_author=>4,
      :no_default_policy=>5,
      :no_title=>6,
      :unknown_auth=>7,
      :success=>0
    }

    #calls populate on an enumeration of resources, and returns an enumeration of responses
    def populate_collection resources
      res=[]
      resources.each do |r|
        res << populate(r)
      end
      return res
    end
    
    #adds a resource to the central SEEK archive, referenced by the remote URI, or creates new version if already exists.
    #returns a report:
    # {:response=>:success|:fail|:skipped,:message=>"",:exception=>Exception|nil,:resource=>resource}
    def populate resource            
      begin
        if resource.uri.blank?
          response={:response=>:fail,:message=>"No URL to data file described"}
        elsif !exists?(resource)
          response=add_as_new(resource)
        else
          response={:response=>:skipped,:message=>MESSAGES[:exists],:response_code=>RESPONSE_CODES[:exists]}
          resource.duplicate=true
        end
      rescue Exception => exception
        response={:response=>:fail,:message=>"Something went wrong",:exception=>exception}
      end
      
      response[:resource]=resource
      response[:uuid]=UUIDTools::UUID.random_create.to_s
      return response
    end

    #checks whether the resource already exists in the registry
    def exists? resource

      exists = false
      
      if (resource.uri.nil?)
        raise Exception.new("URI is nil for resource: #{resource.to_s}")
      end
      
      #Check the URI doesn't exist
      if find_by_uri(resource.uri).nil?
        #Check the file doesn't exist
        #FIXME: Checks project here and again in the embeddedpopulator later on.
        project = Project.find(:first,:conditions=>['name = ?',resource.project]) #get project
        if project.nil?
          return false
        end
#        project.decrypt_credentials
#        downloader = DownloaderFactory.create resource.project
#        begin
#          data_hash = downloader.get_remote_data(resource.uri,project.site_username,project.site_password)
#          
#        rescue Exception=>e
#          puts "Error fetching from :#{resource.uri} - #{e.message}"
#          puts e.backtrace.join("\n")
#          return true
#        end
      
#        unless data_hash.nil?
#          digest = Digest::MD5.new
#          digest << data_hash[:data]
#          md5sum = digest.hexdigest
#          exists = !ContentBlob.find(:first,:conditions=>{:md5sum=>md5sum}).nil?
#        else
#          return false
#        end
         exists=false
      else
        exists = true
      end
      
      return exists
    end

  end
end
