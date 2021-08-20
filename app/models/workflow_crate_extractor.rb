require 'ro_crate'
require 'seek/download_handling/http_streamer'

# A kind of "form object" to create a simple Workflow RO-Crate from ~three files (Workflow, diagram, abstract CWL),
# perform validation (and hold appropriate error messages), and provide output as hash of params that can be used to
# create a ContentBlob.
class WorkflowCrateExtractor
  include ActiveModel::Model

  attr_accessor :ro_crate, :workflow_class

  validates :ro_crate, presence: true
  validate :main_workflow_present?

  def build
    @workflow = Workflow.new(workflow_class: workflow_class)

    if resolve_crate && extract_crate && valid?
      repo = Git::Repository.create!
      gv = @workflow.git_version
      gv.git_repository = repo
      gv.main_workflow_path = URI.decode_www_form_component(@crate.main_workflow.id) if @crate.main_workflow && !@crate.main_workflow.remote?
      gv.diagram_path = URI.decode_www_form_component(@crate.main_workflow.diagram.id) if @crate.main_workflow&.diagram && !@crate.main_workflow.diagram.remote?
      gv.abstract_cwl_path = URI.decode_www_form_component(@crate.main_workflow.cwl_description.id) if @crate.main_workflow&.cwl_description && !@crate.main_workflow.diagram.remote?
      files = []
      @crate.entries.each do |path, entry|
        next if entry.directory?
        files << [path, entry.source]
      end
      gv.add_files(files)

      extractor = @workflow.extractor
      @workflow.provide_metadata(extractor.metadata)

      @workflow
    end

    @workflow
  end

  private

  def main_workflow_present?
    errors.add(:ro_crate, 'did not specify a main workflow.') unless @crate.main_workflow.present?
  end

  def extract_crate
    @crate = ROCrate::WorkflowCrateReader.read_zip(ro_crate[:data].tempfile)
  end

  def resolve_crate
    if ro_crate.nil?
      errors.add(:ro_crate, 'missing')
      false
    elsif ro_crate[:data].blank? && ro_crate[:data_url].present?
      begin
        handler = ContentBlob.remote_content_handler_for(ro_crate[:data_url])
        info = handler.info
        data = handler.fetch
        data.rewind
        ro_crate[:data] = data
        ro_crate[:original_filename] = info[:file_name]
      rescue Seek::DownloadHandling::BadResponseCodeException => e
        errors.add(:ro_crate, "URL could not be accessed: #{e.message}")
        return false
      rescue StandardError => e
        raise e unless Rails.env.production?
        Rails.logger.error("#{e} occurred whilst trying to fetch: #{ro_crate[:data_url]}\n\t#{e.backtrace.join("\n\t")}")
        errors.add(:ro_crate, "URL could not be accessed")
        return false
      end
    end

    true
  end
end
