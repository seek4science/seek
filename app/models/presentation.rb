class Presentation < ApplicationRecord
  attr_accessor :orig_data_file_id

  #searchable must come before acts_as_asset call - although empty is seems this is needed to avoid the autoindex
  #even though in Seek::ActsAsAsset::Search it is already set to false!
  acts_as_asset

  has_one :content_blob, -> (r) { where('content_blobs.asset_version =?', r.version) }, :as => :asset, :foreign_key => :asset_id

  validates :projects, presence: true, projects: { self: true }, unless: Proc.new {Seek::Config.is_virtualliver }

  explicit_versioning(:version_column => "version") do
    acts_as_versioned_resource
    acts_as_favouritable
    has_one :content_blob, -> (r) { where('content_blobs.asset_version =? AND content_blobs.asset_type =?', r.version, r.parent.class.name) },
            :primary_key => :presentation_id,:foreign_key => :asset_id
  end

  has_and_belongs_to_many :events

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
    true
  end
end
