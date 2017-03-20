# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'jerm/populator'

module Jerm
  #A JERM populator that is intended to be used embedded with directly within the SYSMO-DB Rails application - therefore having direct access to the
  #API and Active Record resources.
  class EmbeddedPopulator < Populator    
    
    def find_by_uri uri
      ContentBlob.where({:url=>uri}).first
    end
    
    #adds the resource as a new asset within the registry
    #returns a report:
    # {:response=>:success|:fail|:skipped,:message=>"",:exception=>Exception|nil}
    def add_as_new resource
      #FIXME: this method is too long 
      begin
        warning=nil
        warning_code=0
        project = Project.where(['name = ?',resource.project]).first
        
        if resource.author_seek_id && resource.author_seek_id.to_i>0 #final check it that the string is a number. to_i on String returns 0 if not
          author = Person.find(resource.author_seek_id)
        else
          author = Person.where(['first_name = ? AND last_name = ?',resource.author_first_name,resource.author_last_name]).first
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
          resource_model.original_filename = resource.filename
          
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
          
            #assign default policy, and save the associated asset
            if (resource.authorization==Resource::AUTH_TYPES[:default])
              resource_model.policy=project.default_policy.deep_copy              
            elsif (resource.authorization==Resource::AUTH_TYPES[:sysmo])
              resource_model.policy=sysmo_policy              
            elsif (resource.authorization==Resource::AUTH_TYPES[:project])
              resource_model.policy=project_policy(project)              
            else
              return {:response=>:fail,:message=>MESSAGES[:unknown_auth],:author=>author,:response_code=>RESPONSE_CODES[:unknown_auth]}                                        
            end
            
            resource_model.policy.save!
            resource_model.creators << author
            resource_model.project=project
            resource_model.save!
            resource_model.reload
            resource_model.cache_remote_content_blob
            
            p=Permission.new(:contributor=>author,:access_type=>Policy::MANAGING,:policy_id=>resource_model.policy.id)
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
    
    def sysmo_policy
      Policy.new(:name=>'auto',
                :access_type=>Policy::ACCESSIBLE,
                :use_whitelist=>false,
                :use_blacklist=>false)      
    end
    
    def project_policy project
      policy=Policy.new(:name=>'auto',
                :access_type=>Policy::VISIBLE,
                :use_whitelist=>false,
                :use_blacklist=>false) 
      policy.save!
      p=Permission.new(:contributor=>project,:access_type=>Policy::ACCESSIBLE,:policy_id=>policy.id)
      p.save!
      return policy
    end        
    
    def generated_title resource,author
      type=resource.type.capitalize
      type="SOP" if type.downcase=="sop"
      "#{author.name}'s #{type} #{Time.now.strftime('(%d %b %Y)')}"
    end
    
    def default_policy author,project
      #FIXME: IS THIS USED?
      nil      
    end
  end
end
