require 'ro_crate'
require 'seek/download_handling/http_streamer'

# A kind of "form object" to create a Git repository + version + annotations from a Workflow RO-Crate.
class WorkflowCrateExtractor
  include ActiveModel::Model

  attr_accessor :ro_crate, :workflow_class, :workflow, :git_version, :params, :update_existing

  validate :resolve_crate
  validate :main_workflow_present?, if: -> { @crate.present? }
  validate :source_url_and_version_present?, if: -> { update_existing }
  validate :find_workflows_matching_id, if: -> { update_existing }

  def build
    if valid?
      if update_existing && @existing_workflows.length == 1
        self.workflow = @existing_workflows.first
        if self.workflow.git_versions.map(&:name).include?(@crate['version'])
          return self.workflow
        else
          self.workflow.latest_git_version.lock if self.workflow.latest_git_version.mutable?
          self.git_version = self.workflow.latest_git_version.next_version(mutable: true)
        end
      end
      self.workflow ||= default_workflow
      self.git_version ||= workflow.git_version.tap do |gv|
        gv.set_default_git_repository
      end
      self.git_version.name = @crate['version'] if @crate['version']
      git_version.main_workflow_path = URI.decode_www_form_component(@crate.main_workflow.id) if @crate.main_workflow && !@crate.main_workflow.remote?
      git_version.diagram_path = URI.decode_www_form_component(@crate.main_workflow.diagram.id) if @crate.main_workflow&.diagram && !@crate.main_workflow.diagram.remote?
      git_version.abstract_cwl_path = URI.decode_www_form_component(@crate.main_workflow.cwl_description.id) if @crate.main_workflow&.cwl_description && !@crate.main_workflow.cwl_description.remote?
      files = []
      @crate.entries.each do |path, entry|
        next if entry.directory?
        files << [path, entry.source]
      end
      git_version.add_files(files)

      extractor = Seek::WorkflowExtractors::ROCrate.new(git_version)
      workflow.provide_metadata(extractor.metadata)
      workflow.assign_attributes(params) if params.present?
      git_version.set_resource_attributes(workflow.attributes)
    end

    workflow || default_workflow
  end

  private

  def default_workflow
    Workflow.new(workflow_class: workflow_class)
  end

  def main_workflow_present?
    errors.add(:ro_crate, 'did not specify a main workflow.') unless @crate.main_workflow.present?
  end

  def source_url_and_version_present?
    errors.add(:ro_crate, 'ID could not be determined.') unless @crate.source_url.present?
    errors.add(:ro_crate, 'version could not be determined.') unless @crate['version'].present?
  end

  def find_workflows_matching_id
    # Attempt to find existing workflow
    @existing_workflows = Workflow.find_by_source_url(@crate.source_url)
    if @existing_workflows.length > 1
      errors.add(:ro_crate, "#{@existing_workflows.length} workflows found matching the given ID.")
    end
  end

  def extract_crate
    begin
      @crate = ROCrate::WorkflowCrateReader.read_zip(ro_crate[:data])
    rescue Zip::Error
      errors.add(:ro_crate, 'could not be extracted, please check it is a valid RO-Crate.')
    end
  end

  def resolve_crate
    if ro_crate.nil?
      errors.add(:ro_crate, 'missing')
      return false
    elsif ro_crate[:data].blank?
      if ro_crate[:data_url].present?
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
          Rails.logger.error("#{e} occurred whilst trying to fetch: #{ro_crate[:data_url]}\n\t#{e.backtrace.join("\n\t")}")
          errors.add(:ro_crate, "URL could not be accessed")
          return false
        end
      else
        errors.add(:ro_crate, 'should be provided as a file or remote URL')
        return false
      end
    end

    extract_crate
  end
end
