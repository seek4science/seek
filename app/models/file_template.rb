class FileTemplate < ApplicationRecord
  
  acts_as_annotation_source

  include Seek::Annotatable

  include Seek::Rdf::RdfGeneration
  include Seek::BioSchema::Support

  acts_as_asset

  validates :projects, presence: true, projects: { self: true }

  acts_as_doi_parent(child_accessor: :versions)

  #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates
  has_one :content_blob, -> (r) { where('content_blobs.asset_version = ?', r.version) }, :as => :asset, :foreign_key => :asset_id

  explicit_versioning(version_column: 'version', sync_ignore_columns: ['doi']) do
    acts_as_doi_mintable(proxy: :parent, general_type: 'Text')
    acts_as_versioned_resource
    acts_as_favouritable

    has_one :content_blob, -> (r) { where('content_blobs.asset_version = ? AND content_blobs.asset_type = ?', r.version, r.parent.class.name) },
            primary_key: :file_template_id, foreign_key: :asset_id
  end

  # Returns the columns to be shown on the table view for the resource
  def columns_default
    super + ['version']
  end
  def columns_allowed
    super + ['version','doi','license','last_used_at','other_creators','deleted_contributor']  
  end

  has_annotation_type :mime_type
  has_many :mime_types_as_text, through: :mime_type_annotations, source: :value, source_type: 'TextValue'
  has_filter mime_type: Seek::Filtering::Filter.new(
      value_field: 'text_values.id',
      label_field: 'text_values.text',
      joins: [:mime_types_as_text]
  )

  has_annotation_type :format_type
  has_many :format_types_as_text, through: :format_type_annotations, source: :value, source_type: 'TextValue'
  has_filter format_type: Seek::Filtering::Filter.new(
      value_field: 'text_values.id',
      label_field: 'text_values.text',
      joins: [:format_types_as_text]
  )

  has_annotation_type :data_type
  has_many :data_types_as_text, through: :data_type_annotations, source: :value, source_type: 'TextValue'
  has_filter data_type: Seek::Filtering::Filter.new(
      value_field: 'text_values.id',
      label_field: 'text_values.text',
      joins: [:data_types_as_text]
  )

  def use_mime_type_for_avatar?
    true
  end

end
