class Sop < ApplicationRecord

  include Seek::Rdf::RdfGeneration

  acts_as_asset

  acts_as_doi_parent(child_accessor: :versions)

  validates :projects, presence: true, projects: { self: true }

  #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates
  has_one :content_blob, -> (r) { where('content_blobs.asset_version =?', r.version) }, :as => :asset, :foreign_key => :asset_id

  has_and_belongs_to_many :workflows

  has_filter assay_type: Seek::Filtering::Filter.new(
      value_field: 'assays.assay_type_uri',
      label_mapping: Seek::Filterer::MAPPINGS[:assay_type_label],
      joins: [:assays]
  )
  has_filter technology_type: Seek::Filtering::Filter.new(
      value_field: 'assays.technology_type_uri',
      label_mapping: Seek::Filterer::MAPPINGS[:technology_type_label],
      joins: [:assays]
  )
  
  # Returns the columns to be shown on the table view for the resource
  def columns_default
    super + ['version']
  end
  def columns_allowed
    columns_default + ['last_used_at','other_creators','doi','license']
  end

  explicit_versioning(version_column: 'version', sync_ignore_columns: ['doi']) do
    acts_as_doi_mintable(proxy: :parent, general_type: 'Text')
    acts_as_versioned_resource
    acts_as_favouritable

    has_one :content_blob, -> (r) { where('content_blobs.asset_version =? AND content_blobs.asset_type =?', r.version, r.parent.class.name) },
            :primary_key => :sop_id, :foreign_key => :asset_id
  end

  def organism_title
    organism.nil? ? "" : organism.title
  end

  def human_disease_title
    human_disease.nil? ? "" : human_disease.title
  end

  def use_mime_type_for_avatar?
    true
  end
end
