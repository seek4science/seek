class Workflow < ApplicationRecord
  include Seek::Rdf::RdfGeneration
  include Seek::UploadHandling::ExamineUrl
  include Seek::BioSchema::Support
  include WorkflowExtraction
  include HasTools

  belongs_to :workflow_class, optional: true
  has_filter workflow_type: Seek::Filtering::Filter.new(value_field: 'workflow_classes.key',
                                               label_field: 'workflow_classes.title',
                                               joins: [:workflow_class])

  acts_as_asset

  acts_as_doi_parent

  has_controlled_vocab_annotations :topics, :operations

  validates :projects, presence: true, projects: { self: true }

  #don't add a dependent=>:destroy, as the content_blob needs to remain to detect future duplicates
  has_one :content_blob, -> (r) { where('content_blobs.asset_version =? AND deleted =?', r.version, false) }, :as => :asset, :foreign_key => :asset_id

  has_and_belongs_to_many :sops
  has_and_belongs_to_many :presentations
  has_and_belongs_to_many :documents

  has_many :workflow_data_files, dependent: :destroy, autosave: true
  has_many :data_files, ->{ distinct }, through: :workflow_data_files

  accepts_nested_attributes_for :workflow_data_files

  has_one :execution_instance, -> { where(link_type: AssetLink::EXECUTION_INSTANCE) },
          class_name: 'AssetLink', as: :asset, dependent: :destroy, inverse_of: :asset, autosave: true

  def initialize(*args)
    @extraction_errors = []
    @extraction_warnings = []
    super(*args)
  end

  git_versioning(sync_ignore_columns: ['test_status']) do
    include WorkflowExtraction

    acts_as_doi_mintable(proxy: :parent, general_type: 'Workflow')

    before_save :refresh_internals, if: -> { main_workflow_path_changed? && !main_workflow_blob.empty? }
    after_save :clear_cached_diagram, if: -> { diagram_path_changed? }
    after_commit :submit_to_life_monitor, on: [:create, :update], if: :should_submit_to_life_monitor?
    after_commit :sync_test_status, on: [:create, :update]

    def maturity_level
      Workflow::MATURITY_LEVELS[super]
    end

    def workflow_class
      WorkflowClass.find_by_id(workflow_class_id)
    end

    def search_terms
      terms = []

      main = main_workflow_blob
      terms += main_workflow_blob.text_contents_for_search if main
      readme = git_version.get_blob('README.md')
      terms += readme.text_contents_for_search if readme
      terms
    end

    def test_status
      Workflow::TEST_STATUS[super]
    end

    def test_status= stat
      @only_test_status_changed = changed.empty?
      resource_attributes['test_status'] = (Workflow::TEST_STATUS_INV[stat&.to_sym])
    end

    def source_link_url
      parent&.source_link&.url
    end

    def submit_to_life_monitor
      LifeMonitorSubmissionJob.perform_later(self)
    end

    def should_submit_to_life_monitor?
      Seek::Config.life_monitor_enabled &&
        !@only_test_status_changed &&
        extractor.has_tests? &&
        parent.can_download?(nil)
    end

    # This does two things:
    # 1. If a version's test_status was updated, and it was the latest version, set the test_status on the parent too.
    # 2. If a new version was created, set the parent's test_status to nil, since it will not apply anymore.
    def sync_test_status
      parent.update_column(:test_status, Workflow::TEST_STATUS_INV[test_status]) if latest_git_version?
    end
  end

  explicit_versioning(version_column: 'version', sync_ignore_columns: ['doi', 'test_status']) do
    after_commit :submit_to_life_monitor, on: [:create, :update], if: :should_submit_to_life_monitor?
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

    def execution_instance_url
      parent&.execution_instance&.url
    end

    def submit_to_life_monitor
      LifeMonitorSubmissionJob.perform_later(self)
    end

    def should_submit_to_life_monitor?
      return false if parent.is_git_versioned?

      Seek::Config.life_monitor_enabled &&
        (previous_changes.keys - ['updated_at', 'test_status']).any? &&
        extractor.has_tests? &&
        workflow.can_download?(nil)
    end

    # This does two things:
    # 1. If a version's test_status was updated, and it was the latest version, set the test_status on the parent too.
    # 2. If a new version was created, set the parent's test_status to nil, since it will not apply anymore.
    def sync_test_status
      return if parent.is_git_versioned?
      parent.update_column(:test_status, Workflow::TEST_STATUS_INV[test_status]) if latest_version?
    end

    def avatar_owner
      workflow_class
    end
  end

  attr_reader :extracted_metadata
  attr_reader :extraction_warnings
  attr_reader :extraction_errors

  def provide_metadata(metadata)
    @extraction_warnings = metadata.delete(:warnings) || []
    @extraction_errors = metadata.delete(:errors) || []
    @extracted_metadata = metadata
    assign_attributes(@extracted_metadata)
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

  def defines_own_avatar?
    workflow_class ? workflow_class.defines_own_avatar? : super
  end

  def avatar_owner
    workflow_class
  end

  def avatar_key
    workflow_class ? workflow_class.avatar_key : 'workflow'
  end

  # Expire list item titles when class is updated (in case logo has changed)
  def list_item_title_cache_key_prefix
    (workflow_class ? "#{workflow_class.list_item_title_cache_key_prefix}/#{cache_key}" : super)
  end

  def contributor_credited?
    false
  end

  MATURITY_LEVELS = {
      0 => :work_in_progress,
      1 => :released,
      2 => :deprecated
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

  def execution_instance_url= url
    (execution_instance || build_execution_instance).assign_attributes(url: url)

    execution_instance.mark_for_destruction if url.blank?

    url
  end

  def execution_instance_url
    execution_instance&.url
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

  def self.find_by_source_url(source_url)
    joins(:source_link).where('asset_links.url' => source_url)
  end

  def self.find_existing_version(source_url, version_name)
    workflows = joins(:source_link).where('asset_links.url' => source_url)
    if workflows.length == 1
      workflows.first.git_versions.where(name: version_name)
    elsif workflows.empty?
      'None :('
    else
      'Too many :('
    end
  end

end
