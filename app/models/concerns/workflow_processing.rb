require 'ro_crate_ruby'

module WorkflowProcessing
  extend ActiveSupport::Concern

  def default_diagram_format
    extractor.default_diagram_format
  end

  def can_render_diagram?
    extractor.can_render_diagram?
  end

  def diagram_exists?(format = default_diagram_format)
    file_exists?(cached_diagram_path(format))
  end

  def diagram(format = default_diagram_format)
    path = Pathname.new(cached_diagram_path(format))
    content_type = extractor.class.diagram_formats[format]
    raise(WorkflowDiagram::UnsupportedFormat, "Unsupported diagram format: #{format}") if content_type.nil?

    unless path.exist?
      diagram = extractor.diagram(format)
      return nil if diagram.nil? || diagram.length <= 1
      path.parent.mkdir unless path.parent.exist?
      File.binwrite(path, diagram)
    end

    WorkflowDiagram.new(self, path.to_s)
  end

  def populate_ro_crate(crate)
    c = content_blob
    wf = crate.main_workflow || ROCrate::Workflow.new(crate, c.filepath, c.original_filename)
    wf.content_size = c.file_size
    crate.main_workflow = wf
    crate.main_workflow.programming_language = ROCrate::ContextualEntity.new(crate, nil, workflow_class&.ro_crate_metadata || Seek::WorkflowExtractors::Base::NULL_CLASS_METADATA)

    begin
      d = diagram
      if d&.exists?
        wdf = crate.main_workflow_diagram || ROCrate::WorkflowDiagram.new(crate, d.path, d.filename)
        wdf.content_size = d.size
        crate.main_workflow.diagram = wdf
      end
    rescue WorkflowDiagram::UnsupportedFormat
    end

    authors = creators.map { |person| crate.add_person(nil, person.ro_crate_metadata) }
    others = other_creators&.split(',')&.collect(&:strip)&.compact || []
    authors += others.map.with_index { |name, i| crate.add_person("creator-#{i + 1}", name: name) }
    crate.author = authors
    crate['provider'] = projects.map { |project| crate.add_organization(nil, project.ro_crate_metadata).reference }
    crate.license = license
    crate.identifier = ro_crate_identifier
    crate.url = ro_crate_url('ro_crate')
    crate['isBasedOn'] = source_link_url if source_link_url
    crate['sdPublisher'] = crate.add_person(nil, contributor.ro_crate_metadata).reference
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
    git_annotations.where(key: 'main_workflow').first&.path
  end

  def diagram_path
    git_annotations.where(key: 'diagram').first&.path
  end

  def abstract_cwl_path
    git_annotations.where(key: 'abstract_cwl').first&.path
  end

  private

  def cached_diagram_path(format)
    File.join(Seek::Config.converted_filestore_path, git_repository.uuid, "#{object(diagram_path).oid}.#{format}")
  end
end
