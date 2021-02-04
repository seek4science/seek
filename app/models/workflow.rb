class Workflow < ApplicationRecord
  include Seek::Rdf::RdfGeneration
  include Seek::UploadHandling::ExamineUrl
  include Seek::BioSchema::Support
  include WorkflowExtraction

  belongs_to :workflow_class, optional: true
  has_filter workflow_type: Seek::Filtering::Filter.new(value_field: 'workflow_classes.key',
                                               label_field: 'workflow_classes.title',
                                               joins: [:workflow_class])

  acts_as_asset

  acts_as_doi_parent(child_accessor: :versions)

  validates :projects, presence: true, projects: { self: true }, unless: Proc.new {Seek::Config.is_virtualliver }

  #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates
  has_one :content_blob, -> (r) { where('content_blobs.asset_version =?', r.version) }, :as => :asset, :foreign_key => :asset_id

  has_and_belongs_to_many :sops
  #
  # delegate :workflow_class_title, :extractor_class, :extractor, :default_diagram_format, :can_render_diagram,
  #          :diagram_exists, :diagram, :is_git_ro_crate, :is_already_ro_crate, :is_basic_ro_crate,
  #          :should_generate_crate, :populate_ro_crate, :ro_crate, :ro_crate_zip, :ro_crate_identifier,
  #          :ro_crate_url, :internals, :internals, :inputs, :outputs, :steps, :main_workflow_path,
  #          :diagram_path, :abstract_cwl_path, :cached_diagram_path, :ro_crate_path, to: :git_version

  git_versioning do
    include WorkflowExtraction
    include WorkflowProcessing

    def workflow_class
      WorkflowClass.find_by_id(workflow_class_id)
    end
  end

  explicit_versioning(version_column: 'version', sync_ignore_columns: ['doi']) do
    acts_as_doi_mintable(proxy: :parent, general_type: 'Workflow')
    acts_as_versioned_resource
    acts_as_favouritable

    has_one :content_blob, -> (r) { where('content_blobs.asset_version =? AND content_blobs.asset_type =?', r.version, r.parent.class.name) },
            :primary_key => :workflow_id, :foreign_key => :asset_id

    serialize :metadata

    belongs_to :workflow_class, optional: true
    include WorkflowExtraction

    def maturity_level
      Workflow::MATURITY_LEVELS[super]
    end

    def maturity_level= level
      super(Workflow::MATURITY_LEVELS_INV[level&.to_sym])
    end

    def source_link_url
      parent&.source_link&.url
    end
  end

  attr_reader :extracted_metadata
  def provide_metadata(metadata)
    @extracted_metadata = metadata
    assign_attributes(metadata)
  end

  def avatar_key
    workflow_class&.extractor&.present? ? "#{workflow_class.key.downcase}_workflow" : 'workflow'
  end

  def self.user_creatable?
    Seek::Config.workflows_enabled
  end

  def contributor_credited?
    false
  end

  MATURITY_LEVELS = {
      0 => :work_in_progress,
      1 => :released
  }
  MATURITY_LEVELS_INV = MATURITY_LEVELS.invert

  def maturity_level
    Workflow::MATURITY_LEVELS[super]
  end

  def maturity_level= level
    super(Workflow::MATURITY_LEVELS_INV[level&.to_sym])
  end


  def internals
    JSON.parse(metadata || '{}').with_indifferent_access
  end

  def internals=(meta)
    self.metadata = meta.is_a?(String) ? meta : meta.to_json
  end

  def inputs
    (internals[:inputs] || []).map do |i|
      WorkflowInput.new(self, **i.symbolize_keys)
    end
  end

  def outputs
    (internals[:outputs] || []).map do |o|
      WorkflowOutput.new(self, **o.symbolize_keys)
    end
  end

  def steps
    (internals[:steps] || []).map do |s|
      WorkflowStep.new(self, **s.symbolize_keys)
    end
  end


  has_filter maturity: Seek::Filtering::Filter.new(
      value_field: 'maturity_level',
      label_mapping: ->(values) {
        values.map do |value|
          I18n.translate("maturity_level.#{MATURITY_LEVELS[value]}")
        end
      }
  )
end
