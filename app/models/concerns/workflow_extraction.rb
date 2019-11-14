module WorkflowExtraction
  extend ActiveSupport::Concern

  def extractor_class
    workflow_class.extractor_class
  end

  def extractor
    extractor_class.new(content_blob)
  end

  def default_diagram_format
    extractor_class.default_diagram_format
  end

  def diagram(format = default_diagram_format)
    path = diagram_path(format)
    content_type = extractor_class.diagram_formats[format]
    raise(WorkflowDiagram::UnsupportedFormat, "Unsupported diagram format: #{format}") if content_type.nil?

    unless File.exist?(path)
      diagram = extractor.diagram(format)
      File.binwrite(path, diagram) unless diagram.blank?
    end

    workflow = is_a_version? ? self.parent : self
    WorkflowDiagram.new(workflow, version, path, format, content_type)
  end

  def diagram_available?(format = default_diagram_format)
    File.exist?(diagram_path(format))
  end

  private

  def diagram_path(format)
    content_blob.filepath("diagram.#{format}") # generates a path like "<uuid>.diagram.png"
  end
end
