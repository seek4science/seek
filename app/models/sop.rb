class Sop < ApplicationRecord

  include Seek::Rdf::RdfGeneration

  #searchable must come before acts_as_asset is called
  searchable(:auto_index => false) do
    text :exp_conditions_search_fields
  end if Seek::Config.solr_enabled

  acts_as_asset

  acts_as_doi_parent(child_accessor: :versions)

  validates :projects, presence: true, projects: { self: true }, unless: Proc.new {Seek::Config.is_virtualliver }

  #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates
  has_one :content_blob, -> (r) { where('content_blobs.asset_version =?', r.version) }, :as => :asset, :foreign_key => :asset_id

  has_many :experimental_conditions, -> (r) { where('experimental_conditions.sop_version =?', r.version) }

  has_and_belongs_to_many :workflows

  explicit_versioning(:version_column => "version") do
    acts_as_doi_mintable(proxy: :parent)
    acts_as_versioned_resource
    acts_as_favouritable

    has_one :content_blob, -> (r) { where('content_blobs.asset_version =? AND content_blobs.asset_type =?', r.version, r.parent.class.name) },
            :primary_key => :sop_id, :foreign_key => :asset_id
    has_many :experimental_conditions, -> (r) { where('experimental_conditions.sop_version =?', r.version) },
        :primary_key => "sop_id", :foreign_key => "sop_id"
    
  end

  def organism_title
    organism.nil? ? "" : organism.title
  end

  def use_mime_type_for_avatar?
    true
  end

  #defines that this is a user_creatable object type, and appears in the "New Object" gadget
  def self.user_creatable?
    true
  end
end
