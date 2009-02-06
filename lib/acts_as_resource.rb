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
          
          # a virtual attribute to keep the associated project_id temporary
          # (until it's saved into the corresponding asset in the after_save callback)
          attr_accessor :project_id
                  
          after_save :save_asset_record

          class_eval do
            extend Mib::Acts::Resource::SingletonMethods
          end
          include Mib::Acts::Resource::InstanceMethods
          
          before_create do |res|
            res.asset = Asset.new(:contributor_id => res.contributor_id, :contributor_type => res.contributor_type, :resource => res)
          end
        end
      end
      
      module SingletonMethods
      end
      
      module InstanceMethods
        # TODO decide if useful to keep such method OR everything will be made through Auth module
        #def authorized?(action_name, contributor=nil)
        #  contribution.authorized?(action_name, contributor)
        #end
        
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

private

        # This is so that the updated_at time on the parent Asset record is in sync with the
        # one in the resource record (this will also update the "last_used_at" date for the same reason)
        def save_asset_record
          if(parent_asset = self.asset)
            parent_asset.project_id = self.project_id unless self.project_id.nil?
            parent_asset.last_used_at = self.last_used_at
            parent_asset.save
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
