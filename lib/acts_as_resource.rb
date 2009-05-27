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
          
          has_one :asset, 
                  :as => :resource,
                  :dependent => :destroy
          
          has_many :attributions, 
                   :class_name => 'Relationship',
                   :as => :subject,
                   :conditions => { :predicate => Relationship::ATTRIBUTED_TO },
                   :dependent => :destroy
          
          # a virtual attribute to keep the associated project_id temporary
          # (until it's saved into the corresponding asset in the after_save callback)
          attr_accessor :project_id
          
          # a set of virtual attributes (temporary - same as above) to transfer the data about source and
          # quality of the asset from the new resource into corresponding asset during creation
          attr_accessor :source_type, :source_id, :quality
                  
          after_save :save_asset_record

          class_eval do
            extend Mib::Acts::Resource::SingletonMethods
          end
          include Mib::Acts::Resource::InstanceMethods
          
          before_create do |res|
            res.asset = Asset.new(:contributor_id => res.contributor_id, :contributor_type => res.contributor_type, :resource => res,
                                  :source_type => res.source_type, :source_id => res.source_id, :quality => res.quality)
          end
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
        
        # this method will save the resource, but will not cause 'updated_at' field to receive new value of Time.now
        def save_without_timestamping
          class << self
            def record_timestamps; false; end
          end
    
          save
    
          class << self
            remove_method :record_timestamps
          end
        end



        # the owner of the asset record for this resource
        def owner?(c_utor)
          contribution.owner?(c_utor)
        end
        
        # check if c_utor is the last contributor to edit metadata for this resource
        def last_editor?(c_utor)
          case self.contributor_type
            when "User"
              return (self.contributor_id == c_utor.id && self.contributor_type == c_utor.class.name)
            # TODO some new types of "contributors" may be added at some point - this is to cater for that in future
            # when "Network"
            #   return self.contributor.owner?(c_utor.id) if self.contributor_type.to_s
          else
            # unknown type of contributor - definitely not the owner 
            return false
          end
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

private

        # This is so that the updated_at time on the parent Asset record is in sync with the
        # one in the resource record (this will also update the "last_used_at" date for the same reason)
        def save_asset_record
          if(parent_asset = self.asset)
            parent_asset.project_id = self.project_id unless self.project_id.nil?
            parent_asset.updated_at = self.updated_at
            parent_asset.last_used_at = self.last_used_at
            parent_asset.save_without_timestamping
          else
            logger.error("CRITICAL ERROR: 'asset' object is missing for a resource: (#{self.class.name}, #{self.id}")
          end
        end

      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Mib::Acts::Resource
end
