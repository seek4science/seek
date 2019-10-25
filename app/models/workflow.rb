class Workflow < ApplicationRecord

  include Seek::Rdf::RdfGeneration
  include Seek::UploadHandling::ExamineUrl

  acts_as_asset

  acts_as_doi_parent(child_accessor: :versions)

  validates :projects, presence: true, projects: { self: true }, unless: Proc.new {Seek::Config.is_virtualliver }
  # validate :is_myexperiment?

  #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates
  has_one :content_blob, -> (r) { where('content_blobs.asset_version =?', r.version) }, :as => :asset, :foreign_key => :asset_id

  has_and_belongs_to_many :sops

  explicit_versioning(:version_column => "version") do
    acts_as_doi_mintable(proxy: :parent)
    acts_as_versioned_resource
    acts_as_favouritable

    has_one :content_blob, -> (r) { where('content_blobs.asset_version =? AND content_blobs.asset_type =?', r.version, r.parent.class.name) },
            :primary_key => :workflow_id, :foreign_key => :asset_id
  end

  def use_mime_type_for_avatar?
    true
  end

  def self.user_creatable?
    Seek::Config.workflows_enabled
  end

  def is_github_cwl?
    return (!content_blob.url.nil?) && (content_blob.url.include? 'github.com') && (content_blob.url.end_with? 'cwl')
  end

  def is_myexperiment?
    unless (!content_blob.url.nil?) && (is_myexperiment_url? content_blob.url) && (@is_workflow)
      errors.add(:url, "The URL does not reference a workflow on myExperiment")
    end
  end

  def cwl_viewer_url
    return content_blob.url.sub('https://', 'https://view.commonwl.org/workflows/')
  end
end
