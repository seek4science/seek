require 'ro_crate_ruby'

module WorkflowExtraction
  PREVIEW_TEMPLATE = File.read(File.join(Rails.root, 'script', 'preview.html.erb'))

  extend ActiveSupport::Concern

  def workflow_class_title
    workflow_class ? workflow_class.title : 'Unrecognized workflow type'
  end

  def extractor_class
    workflow_class&.extractor_class || Seek::WorkflowExtractors::Base
  end

  def extractor
    if is_already_ro_crate?
      Seek::WorkflowExtractors::ROCrate.new(content_blob, main_workflow_class: workflow_class)
    elsif is_git_versioned?
      Seek::WorkflowExtractors::GitRepo.new(is_a?(GitVersion) ? self : git_version, main_workflow_class: workflow_class)
    else
      extractor_class.new(content_blob)
    end
  end

  def is_git_ro_crate?
    is_git_versioned? && (file_exists?('.ro-crate-metadata.json') || file_exists?('.ro-crate-metadata.jsonld'))
  end

  def is_already_ro_crate?
    content_blob && content_blob.original_filename.end_with?('.crate.zip') || is_git_ro_crate?
  end

  def is_basic_ro_crate?
    content_blob && content_blob.original_filename.end_with?('.basic.crate.zip')
  end

  def should_generate_crate?
    is_basic_ro_crate? || !is_already_ro_crate?
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

  private

  def ro_crate_path
    content_blob.filepath('crate.zip')
  end
end
