require 'ro_crate'
require 'seek/download_handling/http_streamer'

# A kind of "form object" to create a simple Workflow RO-Crate from ~three files (Workflow, diagram, abstract CWL),
# perform validation (and hold appropriate error messages), and provide output as hash of params that can be used to
# create a ContentBlob.
class WorkflowCrateBuilder
  include ActiveModel::Model

  attr_accessor :main_workflow, :abstract_cwl, :diagram, :workflow_class

  validates :main_workflow, presence: true
  validate :resolve_remotes
  validate :workflow_data_present

  def build
    @workflow = Workflow.new(workflow_class: workflow_class)

    if valid?
      annotations = {}
      main_workflow_filename = get_filename(main_workflow)
      files = [[main_workflow_filename, main_workflow[:data]]]
      annotations['1'] = { key: 'main_workflow', path: main_workflow_filename }
      if diagram && diagram[:data].present?
        diagram_filename = get_filename(diagram)
        files << [diagram_filename, diagram[:data]]
        annotations['2'] = { key: 'diagram', path: diagram_filename }
      end
      if abstract_cwl && abstract_cwl[:data].present?
        abstract_cwl_filename = get_filename(abstract_cwl)
        files << [abstract_cwl_filename, abstract_cwl[:data]]
        annotations['3'] = { key: 'abstract_cwl', path: abstract_cwl_filename }
      end
      repo = GitRepository.create!
      @workflow.local_git_repository = repo
      @workflow.git_version.git_repository = repo
      @workflow.git_version.git_annotations_attributes = annotations
      @workflow.git_version.add_files(files)

      extractor = @workflow.extractor
      @workflow.provide_metadata(extractor.metadata)

      @workflow
    end

    @workflow
  end

  private

  def resolve_remotes
    [:main_workflow, :abstract_cwl, :diagram].each do |attr|
      val = send(attr)
      next if val.nil?
      if val[:data].blank? && val[:data_url].present?
        begin
          handler = ContentBlob.remote_content_handler_for(val[:data_url])
          info = handler.info
          data = handler.fetch
          data.rewind
          assign_attributes(attr => val.merge(data: data, original_filename: info[:file_name]))
        rescue Seek::DownloadHandling::BadResponseCodeException => e
          errors.add(attr, "URL could not be accessed: #{e.message}")
          return false
        rescue StandardError => e
          raise e unless Rails.env.production?
          Rails.logger.error("#{e} occurred whilst trying to fetch: #{val[:data_url]}\n\t#{e.backtrace.join("\n\t")}")
          errors.add(attr, "URL could not be accessed")
          return false
        end
      end
    end

    true
  end

  def workflow_data_present
    if main_workflow && main_workflow[:data].blank?
      errors.add(:main_workflow, 'should be provided as a file or remote URL')
    end
  end

  def get_filename(params)
    original_filename = params[:original_filename]
    original_filename ||= params[:data].original_filename if params[:data].respond_to?(:original_filename)
    original_filename
  end
end
