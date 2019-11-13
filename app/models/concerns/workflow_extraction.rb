module WorkflowExtraction
  extend ActiveSupport::Concern

  def extractor_class
    self.class.const_get("Seek::WorkflowExtractors::#{workflow_class.key}")
  end

  def extractor
    extractor_class.new(content_blob)
  end

  def diagram
    unless File.exist?(diagram_path)
      diagram = extractor.diagram
      File.binwrite(diagram_path, diagram) unless diagram.blank?
    end

    diagram_path
  end

  def diagram_available?
    File.exist?(diagram_path)
  end

  private

  def diagram_path
    content_blob.filepath('diagram.png')
  end
end
