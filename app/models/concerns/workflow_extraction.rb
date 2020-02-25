require 'ro_crate_ruby'

module WorkflowExtraction
  PREVIEW_TEMPLATE = File.read(File.join(Rails.root, 'script', 'preview.html.erb'))

  extend ActiveSupport::Concern

  def extractor_class
    workflow_class.extractor_class
  end

  def extractor
    if is_already_ro_crate?
      Seek::WorkflowExtractors::ROCrate.new(content_blob, inner_extractor_class: extractor_class)
    else
      extractor_class.new(content_blob)
    end
  end

  def default_diagram_format
    extractor.default_diagram_format
  end

  def can_render_diagram?
    extractor.can_render_diagram?
  end

  def diagram(format = default_diagram_format)
    path = diagram_path(format)
    content_type = extractor_class.diagram_formats[format]
    raise(WorkflowDiagram::UnsupportedFormat, "Unsupported diagram format: #{format}") if content_type.nil?

    unless File.exist?(path)
      diagram = extractor.diagram(format)
      File.binwrite(path, diagram) unless diagram.nil? || diagram.length <= 1
    end

    workflow = is_a_version? ? self.parent : self
    WorkflowDiagram.new(workflow, version, path, format, content_type)
  end

  def ro_crate_zip
    unless File.exist?(ro_crate_path)
      if is_already_ro_crate?
        FileUtils.cp(content_blob.filepath, ro_crate_path)
      else
        crate = ro_crate
        ROCrate::Writer.new(crate).write_zip(ro_crate_path)
      end
    end

    ro_crate_path
  end

  def is_already_ro_crate?
    content_blob.original_filename.end_with?('.crate.zip')
  end

  def ro_crate
    return extractor.crate if is_already_ro_crate?

    ROCrate::WorkflowCrate.new.tap do |crate|
      c = content_blob
      wf = ROCrate::Workflow.new(crate, c.filepath, c.original_filename)
      wf.identifier = ro_crate_identifier
      wf.content_size = c.file_size
      crate.main_workflow = wf
      crate.main_workflow.programming_language = ROCrate::ContextualEntity.new(crate, nil, extractor_class.ro_crate_metadata)

      d = diagram
      wdf = ROCrate::WorkflowDiagram.new(crate, d.path, d.filename)
      wdf.content_size = d.size
      crate.main_workflow.diagram = wdf

      crate.date_published = Time.now
      crate.author = related_people.map { |person| crate.add_person(nil, person.ro_crate_metadata) }
      crate.publisher = projects.map { |project| crate.add_organization(nil, project.ro_crate_metadata) }
      crate.license = license
      crate.url = ro_crate_url('ro_crate')

      crate.preview.template = PREVIEW_TEMPLATE
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

  def ro_crate_path
    content_blob.filepath('crate.zip')
  end
end
