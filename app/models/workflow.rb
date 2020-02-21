class Workflow < ApplicationRecord
  include Seek::Rdf::RdfGeneration
  include Seek::UploadHandling::ExamineUrl
  include WorkflowExtraction

  belongs_to :workflow_class
  has_filter workflow_type: Seek::Filtering::Filter.new(value_field: 'workflow_classes.key',
                                               label_field: 'workflow_classes.title',
                                               joins: [:workflow_class])

  acts_as_asset

  acts_as_doi_parent(child_accessor: :versions)

  validates :projects, presence: true, projects: { self: true }, unless: Proc.new {Seek::Config.is_virtualliver }

  #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates
  has_one :content_blob, -> (r) { where('content_blobs.asset_version =?', r.version) }, :as => :asset, :foreign_key => :asset_id

  has_and_belongs_to_many :sops

  explicit_versioning(:version_column => "version") do
    acts_as_doi_mintable(proxy: :parent, general_type: 'Workflow')
    acts_as_versioned_resource
    acts_as_favouritable

    has_one :content_blob, -> (r) { where('content_blobs.asset_version =? AND content_blobs.asset_type =?', r.version, r.parent.class.name) },
            :primary_key => :workflow_id, :foreign_key => :asset_id

    serialize :metadata

    belongs_to :workflow_class
    include WorkflowExtraction
  end

  def avatar_key
    "#{workflow_class.key.downcase}_workflow"
  end

  def self.user_creatable?
    Seek::Config.workflows_enabled
  end
end
