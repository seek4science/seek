class FileTemplate < ApplicationRecord
  
  acts_as_annotation_source

  include Seek::Annotatable

  include Seek::Rdf::RdfGeneration
  include Seek::BioSchema::Support

  acts_as_asset

  validates :projects, presence: true, projects: { self: true }

  acts_as_doi_parent

  has_controlled_vocab_annotations :data_types, :data_formats

  #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates
  has_one :content_blob, -> (r) { where('content_blobs.asset_version = ?', r.version) }, :as => :asset, :foreign_key => :asset_id

  has_many :data_files, inverse_of: :file_template
  has_many :placeholders, inverse_of: :file_template

  explicit_versioning(version_column: 'version', sync_ignore_columns: ['doi']) do
    acts_as_doi_mintable(proxy: :parent, general_type: 'Text')
    acts_as_versioned_resource
    acts_as_favouritable

    has_one :content_blob, -> (r) { where('content_blobs.asset_version = ? AND content_blobs.asset_type = ?', r.version, r.parent.class.name) },
            primary_key: :file_template_id, foreign_key: :asset_id
  end

  def use_mime_type_for_avatar?
    true
  end

  def supports_spreadsheet_explore?
    true
  end

  def self.user_creatable?
    Seek::Config.file_templates_enabled
  end
  
end
