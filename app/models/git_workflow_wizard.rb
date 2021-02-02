require 'ro_crate_ruby'
require 'seek/download_handling/http_streamer'

# A kind of "form object" to instantiate a workflow from a given git repository, target ref, and several paths in that
# repository that indicate where to find the main workflow, diagram etc..
# Alternatively, these paths can be inferred from RO-Crate metadata, if present.
#
class GitWorkflowWizard
  include ActiveModel::Model

  attr_accessor :git_repository_id,
                :ref,
                :main_workflow_path,
                :abstract_cwl_path,
                :diagram_path,
                :workflow_class_id

  validates :git_repository_id, presence: true
  validates :ref, presence: true
  validates :main_workflow_path, presence: true
  validates :workflow_class_id, presence: true

  def run
    @next_step = nil
    workflow = Workflow.new(git_version_attributes: { git_repository_id: git_repository_id, ref: ref })
    workflow_class = WorkflowClass.find_by_id(workflow_class_id)
    if workflow.file_exists?('.ro-crate-metadata.json') ||  workflow.file_exists?('.ro-crate-metadata.jsonld')
      workflow.in_temp_dir do |dir|
        crate = ROCrate::WorkflowCrateReader.read(dir)
        self.main_workflow_path = crate.main_workflow&.id if crate.main_workflow&.id
        self.diagram_path = crate.main_workflow&.diagram&.id if crate.main_workflow&.diagram&.id
        self.abstract_cwl_path = crate.main_workflow&.cwl_description&.id if crate.main_workflow&.cwl_description&.id

        workflow_class ||= WorkflowClass.match_from_metadata(crate&.main_workflow&.programming_language&.properties || {})
      end
    end

    unless main_workflow_path
      @next_step = :select_paths
      return workflow
    end

    workflow.workflow_class = workflow_class
    annotations = {}
    annotations['1'] = { key: 'main_workflow', path: main_workflow_path } unless main_workflow_path.blank?
    annotations['2'] = { key: 'diagram', path: diagram_path } unless diagram_path.blank?
    annotations['3'] = { key: 'abstract_cwl', path: abstract_cwl_path } unless abstract_cwl_path.blank?
    workflow.git_version_attributes = workflow.git_version_attributes.merge(git_annotations_attributes: annotations)

    extractor = workflow.extractor
    workflow.provide_metadata(extractor.metadata)

    @next_step = :provide_metadata

    workflow
  end

  def next_step
    @next_step
  end
end
