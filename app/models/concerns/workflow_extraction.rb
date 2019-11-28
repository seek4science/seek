require 'ro_crate_ruby'

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

  def ro_crate_metadata
    {
        id: "#workflow-#{id}",
        name: title,
        identifier: doi ? doi : rdf_seek_id
    }
  end

  def ro_crate
    ROCrate::Crate.new.tap do |crate|
      c = content_blob
      wf = crate.add_file(c.filepath, path: c.original_filename)
      wf.identifier = ro_crate_identifier
      wf.content_size = c.file_size
      wf.type = ["File", "SoftwareSourceCode", "Workflow"]

      d = diagram
      wdf = crate.add_file(d.path, path: d.filename)
      wdf.content_size = d.size
      wdf.type = ["File", "ImageObject", "WorkflowSketch"]
      wdf.properties['about'] = wf.reference
      crate.date_published = Time.now
      crate.author = related_people.map { |person| crate.add_person(nil, person.ro_crate_metadata) }
      crate.license = license
    end
  end

  def ro_crate_identifier
    if doi.present?
      doi
    else
      parts = [Seek::Config.site_base_host.chomp('/')]
      if is_a_version?
        parts += [parent.class.name.tableize, parent.id.to_s, "?version=#{version}"]
      else
        parts += [self.class.name.tableize, self.id.to_s, "?version=#{version}"]
      end

      URI.join(*parts)
    end
    doi.present? ? doi : URI.join(Seek::Config.site_base_host + '/', "#{self.class.name.tableize}/", id.to_s).to_s
  end

  private

  def diagram_path(format)
    content_blob.filepath("diagram.#{format}") # generates a path like "<uuid>.diagram.png"
  end
end
