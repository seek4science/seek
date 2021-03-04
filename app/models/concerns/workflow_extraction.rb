require 'ro_crate'

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
    if is_git_ro_crate?
      Seek::WorkflowExtractors::ROCrate.new(is_a?(GitVersion) ? self : git_version, main_workflow_class: workflow_class)
    elsif is_already_ro_crate?
      Seek::WorkflowExtractors::ROCrate.new(content_blob, main_workflow_class: workflow_class)
    elsif is_git_versioned?
      Seek::WorkflowExtractors::GitRepo.new(is_a?(GitVersion) ? self : git_version, main_workflow_class: workflow_class)
    else
      extractor_class.new(content_blob)
    end
  end

  def default_diagram_format
    Rails.cache.fetch("#{cache_key_with_version}/default_diagram_format", expires_in: 3.days) do
      extractor.default_diagram_format
    end
  end

  def has_tests?
    extractor.has_tests?
  end

  def can_render_diagram?
    extractor.can_render_diagram?
  end

  def diagram_exists?(format = default_diagram_format)
    path = diagram_path(format)
    File.exist?(path)
  end

  def diagram(format = default_diagram_format)
    path = diagram_path(format)
    content_type = extractor_class.diagram_formats[format]
    raise(WorkflowDiagram::UnsupportedFormat, "Unsupported diagram format: #{format}") if content_type.nil?

    unless File.exist?(path)
      diagram = extractor.diagram(format)
      return nil if diagram.nil? || diagram.length <= 1
      File.binwrite(path, diagram)
    end

    workflow = is_a_version? ? self.parent : self
    WorkflowDiagram.new(workflow, version, path, format, content_type)
  end

  def is_git_ro_crate?
    is_git_versioned? && (file_exists?('ro-crate-metadata.json') || file_exists?('ro-crate-metadata.jsonld'))
  end

  def is_already_ro_crate?
    content_blob && content_blob.original_filename.end_with?('.crate.zip')
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
