class Document < ApplicationRecord

  include Seek::Rdf::RdfGeneration
  include Seek::BioSchema::Support

  acts_as_asset

  validates :projects, presence: true, projects: { self: true }

  acts_as_doi_parent

  #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates
  has_one :content_blob, -> (r) { where('content_blobs.asset_version = ?', r.version) }, :as => :asset, :foreign_key => :asset_id

  has_and_belongs_to_many :workflows, -> { distinct }

  if Seek::Config.events_enabled
    has_and_belongs_to_many :events
    before_destroy {events.clear}
    enforce_authorization_on_association :events, :view
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

  explicit_versioning(version_column: 'version', sync_ignore_columns: ['doi']) do
    acts_as_doi_mintable(proxy: :parent, general_type: 'Text')
    acts_as_versioned_resource
    acts_as_favouritable

    has_one :content_blob, -> (r) { where('content_blobs.asset_version = ? AND content_blobs.asset_type = ?', r.version, r.parent.class.name) },
            primary_key: :document_id, foreign_key: :asset_id
  end

  def supports_spreadsheet_explore?
    true
  end

  def use_mime_type_for_avatar?
    true
  end
end
