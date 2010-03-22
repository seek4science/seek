# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'jerm/populator'

module Jerm
  #A JERM populator that is intended to be used embedded with directly within the SYSMO-DB Rails application - therefore having direct access to the
  #API and Active Record resources.
  class EmbeddedPopulator < Populator    

    def find_by_uri uri
      ContentBlob.find(:first,:conditions=>{:url=>uri})
    end

    #adds the resource as a new asset within the registry
    #returns a report:
    # {:response=>:success|:fail|:skipped,:message=>"",:exception=>Exception|nil}
    def add_as_new resource
	#FIXME: this method is too long 
      begin
        warning=nil
        warning_code=0
        project = Project.find(:first,:conditions=>['name = ?',resource.project])
      
        if resource.author_seek_id && resource.author_seek_id.to_i>0 #final check it that the string is a number. to_i on String returns 0 if not
          author = Person.find(resource.author_seek_id)
        else
          author = Person.find(:first,:conditions=>['first_name = ? AND last_name = ?',resource.author_first_name,resource.author_last_name])
        end
        
        if project.nil?
          response={:response=>:fail,:message=>MESSAGES[:no_project],:response_code=>RESPONSE_CODES[:no_project]}
        elsif author.nil?
          response={:response=>:fail,:message=>MESSAGES[:no_author],:response_code=>RESPONSE_CODES[:no_author]}
        elsif resource.uri.nil?
          response={:response=>:fail,:message=>MESSAGES[:no_uri],:response_code=>RESPONSE_CODES[:no_uri]}
        else
          #create SOP,DataFile or Model (or other type that may be added in the future)        
          resource_model=eval("#{resource.type}.new")
          #resource_model.contributor=author.user
          #associate with ContentBlob
          resource_model.content_blob = ContentBlob.new(:url=>resource.uri)
          resource_model.original_filename = determine_filename(resource)

          if resource.title.blank?
            warning = MESSAGES[:no_title]
            warning_code=RESPONSE_CODES[:no_title]
            resource.title=generated_title(resource,author)
          end
          
          resource_model.title=resource.title
          resource_model.description=resource.description unless resource.description.blank?
          
          if project.default_policy.nil?
            response={:response=>:fail,:message=>MESSAGES[:no_default_policy],:author=>author,:response_code=>RESPONSE_CODES[:no_default_policy]}
          else
            #save it
            #FIXME: try and avoid this double save - its currently done here to create the Asset before connecting to the policy. If unavoidable, do as a transaction with rollback on failure
            resource_model.save!
            resource_model.asset.project=project
            
            #assign default policy, and save the associated asset

            resource_model.asset.policy=project.default_policy.deep_copy
            resource_model.asset.policy.use_custom_sharing = true
            resource_model.asset.creators << author
            resource_model.asset.save!
            resource_model.project=project
            resource_model.save!
            resource_model.reload
            resource_model.cache_remote_content_blob

            p=Permission.new(:contributor=>author,:access_type=>Policy::MANAGING,:policy_id=>resource_model.asset.policy.id)
            p.save!
            if warning
              response={:response=>:warning,:message=>warning,:author=>author,:seek_model=>resource_model,:response_code=>warning_code}
            else
              response={:response=>:success,:message=>MESSAGES[:success],:author=>author,:seek_model=>resource_model,:response_code=>RESPONSE_CODES[:success]}
            end            
          end
          
        end
      rescue Exception=>exception
        response={:response=>:fail,:message=>"Something went wrong",:exception=>exception}
      end
      return response
    end

    def determine_filename resource
      URI.unescape(resource.uri).split("/").last
    end

    def generated_title resource,author
      type=resource.type.capitalize
      type="SOP" if type.downcase=="sop"
      "#{author.name}'s #{type} #{Time.now.strftime('(%d %b %Y)')}"
    end

    def default_policy author,project
      nil
      #      Policy.new(:name => 'auto',
      #        :contributor_type => 'User',
      #        :contributor_id => author.user.id,
      #        :sharing_scope => Policy::EVERYONE,
      #        :access_type => Policy::DOWNLOADING,
      #        :use_custom_sharing => false,
      #        :use_whitelist => false,
      #        :use_blacklist => false)
    end
  end
end
