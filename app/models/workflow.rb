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

  has_edam_annotations

  validates :projects, presence: true, projects: { self: true }, unless: Proc.new {Seek::Config.is_virtualliver }

  #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates
  has_one :content_blob, -> (r) { where('content_blobs.asset_version =?', r.version) }, :as => :asset, :foreign_key => :asset_id

  has_and_belongs_to_many :sops
  has_and_belongs_to_many :presentations
  has_and_belongs_to_many :documents

  has_many :workflow_data_files, dependent: :destroy, autosave: true
  has_many :data_files, ->{ distinct }, through: :workflow_data_files

  accepts_nested_attributes_for :workflow_data_files

  explicit_versioning(version_column: 'version', sync_ignore_columns: ['doi', 'test_status']) do
    after_commit :submit_to_life_monitor, on: [:create, :update]
    after_commit :sync_test_status, on: [:create, :update]
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

    def test_status
      Workflow::TEST_STATUS[super]
    end

    def test_status= stat
      super(Workflow::TEST_STATUS_INV[stat&.to_sym])
    end

    def source_link_url
      parent&.source_link&.url
    end

    def submit_to_life_monitor
      if Seek::Config.life_monitor_enabled && !monitored && extractor.has_tests? && workflow.can_download?(nil)
        LifeMonitorSubmissionJob.perform_later(self)
      end
    end

    # This does two things:
    # 1. If a version's test_status was updated, and it was the latest version, set the test_status on the parent too.
    # 2. If a new version was created, set the parent's test_status to nil, since it will not apply anymore.
    def sync_test_status
      parent.update_column(:test_status, Workflow::TEST_STATUS_INV[test_status]) if latest_version?
    end
  end

  def workflow_data_files_attributes=(attributes)
    self.workflow_data_files.each do |link|
      if link.workflow_data_file_relationship
        link.mark_for_destruction unless attributes.include?({"data_file_id"=>link.data_file.id.to_s,"workflow_data_file_relationship_id"=>link.workflow_data_file_relationship.id.to_s })
      else
        link.mark_for_destruction unless attributes.include?({"data_file_id"=>link.data_file.id.to_s})
      end
    end
    attributes.each do |attr|
      if self.workflow_data_files.where(attr).empty?
        self.workflow_data_files.build(attr)
      end
    end
  end

  def avatar_key
    workflow_class&.extractor&.present? ? "#{workflow_class.key.downcase}_workflow" : 'workflow'
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

  TEST_STATUS = {
      0 => :not_available,
      1 => :all_failing,
      2 => :some_passing,
      3 => :all_passing
  }
  TEST_STATUS_INV = TEST_STATUS.invert

  def test_status
    Workflow::TEST_STATUS[super]
  end

  def update_test_status(status, ver = version)
    v = find_version(ver)
    v.test_status = status
    v.save!
  end

  has_filter maturity: Seek::Filtering::Filter.new(
      value_field: 'maturity_level',
      label_mapping: ->(values) {
        values.map do |value|
          I18n.translate("maturity_level.#{MATURITY_LEVELS[value]}")
        end
      }
  )

  has_filter tests: Seek::Filtering::Filter.new(
      value_field: 'test_status',
      label_mapping: ->(values) {
        values.map do |value|
          I18n.translate("test_status.#{TEST_STATUS[value]}")
        end
      }
  )
end
