require 'ro_crate'
require 'seek/download_handling/http_streamer'

# A kind of "form object" to create a simple Workflow RO-Crate from ~three files (Workflow, diagram, abstract CWL),
# perform validation (and hold appropriate error messages), and provide output as hash of params that can be used to
# create a ContentBlob.
class WorkflowCrateExtractor
  include ActiveModel::Model

  attr_accessor :ro_crate, :workflow_class

  validates :ro_crate, presence: true
  validate :resolve_remotes

  def build
    @workflow = Workflow.new(workflow_class: workflow_class)

    if valid?
      crate = ROCrate::WorkflowCrateReader.read_zip(ro_crate[:data].tempfile)
      annotations = {}
      annotations['1'] = { key: 'main_workflow', path: crate.main_workflow.source.path } if crate.main_workflow
      annotations['2'] = { key: 'diagram', path: crate.main_workflow.diagram.source.path } if crate.main_workflow&.diagram
      annotations['3'] = { key: 'abstract_cwl', path: crate.main_workflow.cwl_description.source.path } if crate.main_workflow&.cwl_description
      repo = GitRepository.create!
      @workflow.git_version_attributes = @workflow.git_version_attributes.merge(git_repository_id: repo.id,
                                                                                git_annotations_attributes: annotations)
      files = []
      crate.entries.each do |path, entry|
        files << [path, entry.source]
      end
      @workflow.git_version.add_files(files)

      extractor = @workflow.extractor
      @workflow.provide_metadata(extractor.metadata)

      @workflow
    end

    @workflow
  end

  private

  def resolve_remotes
    if ro_crate[:data].blank? && ro_crate[:data_url].present?
      begin
        handler = ContentBlob.remote_content_handler_for(ro_crate[:data_url])
        info = handler.info
        data = handler.fetch
        data.rewind
        ro_crate[:data] = data
        ro_crate[:original_filename] = info[:file_name]
      rescue Seek::DownloadHandling::BadResponseCodeException => e
        errors.add(attr, "URL could not be accessed: #{e.message}")
        return false
      rescue StandardError => e
        raise e unless Rails.env.production?
        Rails.logger.error("#{e} occurred whilst trying to fetch: #{ro_crate[:data_url]}\n\t#{e.backtrace.join("\n\t")}")
        errors.add(attr, "URL could not be accessed")
        return false
      end
    end

    true
  end
end
