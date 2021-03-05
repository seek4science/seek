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
      Seek::WorkflowExtractors::ROCrate.new(git_version, main_workflow_class: workflow_class)
    elsif is_already_ro_crate?
      Seek::WorkflowExtractors::ROCrate.new(content_blob, main_workflow_class: workflow_class)
    elsif is_git_versioned?
      Seek::WorkflowExtractors::GitRepo.new(git_version, main_workflow_class: workflow_class)
    else
      extractor_class.new(content_blob)
    end
  end

  delegate :default_diagram_format, :can_render_diagram?, :has_tests?, to: :extractor

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

  def diagram_exists?(format = default_diagram_format)
    if is_git_versioned?
      file_exists?(cached_diagram_path(format))
    else
      File.exist?(cached_diagram_path(format))
    end
  end

  def diagram(format = default_diagram_format)
    path = Pathname.new(cached_diagram_path(format))
    content_type = extractor.class.diagram_formats[format]
    raise(WorkflowDiagram::UnsupportedFormat, "Unsupported diagram format: #{format}") if content_type.nil?

    unless path.exist?
      diagram = extractor.generate_diagram(format)
      return nil if diagram.nil? || diagram.length <= 1
      path.parent.mkdir unless path.parent.exist?
      File.binwrite(path, diagram)
    end

    WorkflowDiagram.new(self, path.to_s)
  end

  def populate_ro_crate(crate)
    if is_git_versioned?
      file = file_contents(main_workflow_path)
      crate.main_workflow = ROCrate::Workflow.new(crate, StringIO.new(file), main_workflow_path, content_size: file.length)
      if file_exists?(diagram_path)
        crate.main_workflow.diagram = ROCrate::WorkflowDiagram.new(crate, StringIO.new(file_contents(diagram_path)), diagram_path)
      end
      if file_exists?(abstract_cwl_path)
        crate.main_workflow.cwl_description = ROCrate::WorkflowDescription.new(crate, StringIO.new(file_contents(abstract_cwl_path)), abstract_cwl_path)
      end
    else
      unless crate.main_workflow
        crate.main_workflow = ROCrate::Workflow.new(crate, content_blob.filepath, content_blob.original_filename, content_size: content_blob.file_size)
      end
      begin
        d = diagram
        if d&.exists?
          wdf = crate.main_workflow_diagram || ROCrate::WorkflowDiagram.new(crate, d.path, d.filename)
          wdf.content_size = d.size
          crate.main_workflow.diagram = wdf
        end
      rescue WorkflowDiagram::UnsupportedFormat
      end
    end

    crate.main_workflow.programming_language = ROCrate::ContextualEntity.new(crate, nil, workflow_class&.ro_crate_metadata || Seek::WorkflowExtractors::Base::NULL_CLASS_METADATA)
    authors = creators.map { |person| crate.add_person(nil, person.ro_crate_metadata) }
    others = other_creators&.split(',')&.collect(&:strip)&.compact || []
    authors += others.map.with_index { |name, i| crate.add_person("creator-#{i + 1}", name: name) }
    crate.author = authors
    crate['provider'] = projects.map { |project| crate.add_organization(nil, project.ro_crate_metadata).reference }
    crate.license = license
    crate.identifier = ro_crate_identifier
    crate.url = ro_crate_url('ro_crate')
    crate['isBasedOn'] = source_link_url if source_link_url
    crate['sdPublisher'] = crate.add_person(nil, contributor.ro_crate_metadata).reference if contributor
    crate['sdDatePublished'] = Time.now
    crate['creativeWorkStatus'] = I18n.t("maturity_level.#{maturity_level}") if maturity_level

    crate.preview.template = PREVIEW_TEMPLATE
  end

  def ro_crate
    inner = proc do |crate|
      populate_ro_crate(crate) if should_generate_crate?

      if block_given?
        yield crate
      else
        return crate
      end
    end

    if is_already_ro_crate?
      extractor.open_crate(&inner)
    else
      ROCrate::WorkflowCrate.new.tap(&inner)
    end
  end

  def ro_crate_zip
    ro_crate do |crate|
      ROCrate::Writer.new(crate).write_zip(ro_crate_path)
    end

    ro_crate_path
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

  def main_workflow_path
    find_git_annotation('main_workflow')&.path
  end

  def diagram_path
    find_git_annotation('diagram')&.path
  end

  def abstract_cwl_path
    find_git_annotation('abstract_cwl')&.path
  end

  private

  def ro_crate_path
    if is_git_versioned?
      "git_version_#{git_version.id}_diagram.#{format}"
    else
      content_blob.filepath('crate.zip')
    end
  end

  def cached_diagram_path(format)
    if is_git_versioned?
      File.join(Seek::Config.converted_filestore_path, "git_version_#{git_version.id}_diagram.#{format}")
    else
      content_blob.filepath("diagram.#{format}")
    end
  end
end
