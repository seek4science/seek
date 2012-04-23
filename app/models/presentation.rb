require 'acts_as_asset'
require 'grouped_pagination'
require 'explicit_versioning'
require 'acts_as_versioned_resource'

class Presentation < ActiveRecord::Base

   attr_accessor :orig_data_file_id

   acts_as_asset
   belongs_to :content_blob

   validates_presence_of :content_blob

   searchable(:ignore_attribute_changes_of=>[:updated_at,:last_used_at]) do
    text :description,:title,:original_filename,:searchable_tags
   end if Seek::Config.solr_enabled

   explicit_versioning(:version_column => "version") do
    acts_as_versioned_resource
    belongs_to :content_blob
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
  def self.get_all_as_json(user)
    all = Presentation.all_authorized_for "view",user
    with_contributors = all.collect{ |d|
        contributor = d.contributor;
        { "id" => d.id,
          "title" => d.title,
          "contributor" => contributor.nil? ? "" : "by " + contributor.person.name,
          "type" => self.name
        }
    }
    return with_contributors.to_json
  end

   #defines that this is a user_creatable object type, and appears in the "New Object" gadget
  def self.user_creatable?
    true
  end

  def validate
   # errors.add_to_base "Your file is not in PDF format!" unless content_type=="application/pdf"

  end
end