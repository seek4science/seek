
require 'explicit_versioning'
require 'acts_as_versioned_resource'

class Presentation < ActiveRecord::Base

   attr_accessor :orig_data_file_id

   acts_as_asset

   scope :default_order, order("title")

   has_one :content_blob, :as => :asset, :foreign_key => :asset_id ,:conditions => Proc.new{["content_blobs.asset_version =?", version]}

   explicit_versioning(:version_column => "version") do
     acts_as_versioned_resource
     acts_as_favouritable
     has_one :content_blob,:primary_key => :presentation_id,:foreign_key => :asset_id,:conditions => Proc.new{["content_blobs.asset_version =? AND content_blobs.asset_type =?", version, parent.class.name]}
  end

   if Seek::Config.events_enabled
    has_and_belongs_to_many :events
  else
    def events
      []
    end

    def event_ids
      []
    end

    def event_ids= events_ids

    end
  end

  # get a list of Presentations with their original uploaders - for autocomplete fields
  # (authorization is done immediately to save from iterating through the collection again afterwards)
  #
  # Parameters:
  # - user - user that performs the action; this is required for authorization


   #defines that this is a user_creatable object type, and appears in the "New Object" gadget
  def self.user_creatable?
    true
  end

  def use_mime_type_for_avatar?
    true
  end

  def is_in_isa_publishable?
    false
  end
end