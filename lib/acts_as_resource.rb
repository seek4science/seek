# SysMO: lib/acts_as_resource.rb
# Original code borrowed from myExperiment and tailored for SysMO needs.

# ********************************************************************************
# * myExperiment: lib/acts_as_contributable.rb
# *
# * Copyright (c) 2007 University of Manchester and the University of Southampton.
# * See license.txt for details.
# ********************************************************************************

module Mib
  module Acts #:nodoc:
    module Resource #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_resource
          belongs_to :contributor, :polymorphic => true
          
          has_many :attributions, 
            :class_name => 'Relationship',
            :as => :subject,
            :conditions => { :predicate => Relationship::ATTRIBUTED_TO },
            :dependent => :destroy

          belongs_to :project
          
          belongs_to :policy 

          has_many :assay_assets, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
          has_many :assays, :through => :assay_assets
  
          has_many :assets_creators, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
          has_many :creators, :class_name => "Person" , :through => :assets_creators

          class_eval do
            extend Mib::Acts::Resource::SingletonMethods
          end
          include Mib::Acts::Resource::InstanceMethods
          
        end
      end
      
      module SingletonMethods
      end
      
      module InstanceMethods
        # this method will take attributions' association and return a collection of resources,
        # to which the current resource is attributed
        def attributions_objects
          self.attributions.collect { |a| a.object }
        end

        def can_edit? user
          Authorization.is_authorized? "edit",nil,self,user
        end

        def can_view? user
          Authorization.is_authorized? "view",nil,self,user
        end

        def can_download? user
          Authorization.is_authorized? "download",nil,self,user
        end

        def can_delete? user
          Authorization.is_authorized? "destroy",nil,self,user
        end
      
        def cache_remote_content_blob
          if self.content_blob && self.content_blob.data.nil? && self.content_blob.url && self.project
            begin
              p=self.project
              p.decrypt_credentials
              downloader=Jerm::DownloaderFactory.create p.name
              resource_type = self.class.name.split("::")[0] #need to handle versions, e.g. Sop::Version
              data_hash = downloader.get_remote_data self.content_blob.url,p.site_username,p.site_password, resource_type
              self.content_blob.data=data_hash[:data]
              self.content_type=data_hash[:content_type]
              self.content_blob.save
              self.save              
            rescue Exception=>e
              puts "Error caching remote data for url=#{self.content_blob.url} #{e.message[0..50]} ..."
            end
          end
        end

        #returns a list of the people that can manage this file
        #which will be the contributor, and those that have manage permissions
        def managers
          people=[]
          people << self.contributor.person unless self.contributor.nil?
          self.policy.permissions.each do |perm|
            people << (perm.contributor) if perm.contributor.kind_of?(Person) && perm.access_type==Policy::MANAGING
          end
          return people.uniq
        end
        
       # def asset; return self; end        
       # def resource; return self; end
          
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Mib::Acts::Resource
end
