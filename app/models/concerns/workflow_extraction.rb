require 'ro_crate_ruby'

module WorkflowExtraction
  extend ActiveSupport::Concern

  def extractor_class
    if content_blob.original_filename.end_with?('.crate.zip')
      Seek::WorkflowExtractors::ROCrate
    else
      workflow_class.extractor_class
    end
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

  def ro_crate
    ROCrate::WorkflowCrate.new.tap do |crate|
      c = content_blob
      wf = ROCrate::Workflow.new(crate, c.filepath, c.original_filename)
      wf.identifier = ro_crate_identifier
      wf.content_size = c.file_size
      crate.main_workflow = wf

      d = diagram
      wdf = ROCrate::WorkflowDiagram.new(crate, d.path, d.filename)
      wdf.content_size = d.size
      crate.main_workflow.diagram = wdf

      crate.date_published = Time.now
      crate.author = related_people.map { |person| crate.add_person(nil, person.ro_crate_metadata) }
      crate.publisher = projects.map { |project| crate.add_organization(nil, project.ro_crate_metadata) }
      crate.license = license
      crate.url = ro_crate_url('ro_crate')
    end
  end

  def ro_crate_identifier
    doi.present? ? doi : ro_crate_url
  end

  def ro_crate_url(action = nil)
    url = Seek::Config.site_base_host.chomp('/')
    wf = is_a_version? ? parent : self
    url += "/#{wf.class.name.tableize}/#{wf.id}"
    url += "/#{action}" if action
    url += "?version=#{version}"

    url
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

  def diagram_path(format)
    content_blob.filepath("diagram.#{format}") # generates a path like "<uuid>.diagram.png"
  end
end
