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
    def add_as_new resource      
      project = Project.find(:first,:conditions=>['name = ?',resource.project])
      if resource.author_seek_id
        author = Person.find(resource.author_seek_id)
      else
        author = Person.find(:first,:conditions=>['first_name = ? AND last_name = ?',resource.author_first_name,resource.author_last_name])
      end

      #create SOP,DataFile or Model (or other type that may be added in the future)
      resource_model=eval("#{resource.type}.new")
      resource_model.project=project
      resource_model.title=resource.uri
      resource_model.contributor=author.user
      #associate with ContentBlob
      resource_model.content_blob = ContentBlob.new(:url=>resource.uri)
      resource_model.original_filename = "fred.pdf"
      #save it
      resource_model.save!
      #assign default policy, and save the associated asset
      policy = default_policy(author,project)
      resource_model.asset.policy=policy
      resource_model.asset.save!
     
    end

    def default_policy author,project
      Policy.new(:name => 'auto',
                          :contributor_type => 'User',
                          :contributor_id => author.user.id,
                          :sharing_scope => Policy::EVERYONE,
                          :access_type => Policy::VIEWING,
                          :use_custom_sharing => false,
                          :use_whitelist => false,
                          :use_blacklist => false)
    end
  end
end
