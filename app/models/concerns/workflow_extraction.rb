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
    if is_already_ro_crate?
      Seek::WorkflowExtractors::ROCrate.new(content_blob, main_workflow_class: workflow_class)
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

  def can_run?
    can_download?(nil) && workflow_class_title == 'Galaxy' && Seek::Config.galaxy_instance_trs_import_url.present?
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

  def is_already_ro_crate?
    content_blob.original_filename.end_with?('.crate.zip')
  end

  def is_basic_ro_crate?
    content_blob.original_filename.end_with?('.basic.crate.zip')
  end

  def should_generate_crate?
    is_basic_ro_crate? || !is_already_ro_crate?
  end

  def populate_ro_crate(crate)
    c = content_blob
    wf = crate.main_workflow || ROCrate::Workflow.new(crate, c.filepath, c.original_filename)
    wf.content_size = c.file_size
    crate.main_workflow = wf
#    crate.main_workflow.programming_language = ROCrate::ContextualEntity.new(crate, nil, extractor_class.ro_crate_metadata)

    begin
      d = diagram
      if d&.exists?
        wdf = crate.main_workflow_diagram || ROCrate::WorkflowDiagram.new(crate, d.path, d.filename)
        wdf.content_size = d.size
        crate.main_workflow.diagram = wdf
      end
    rescue WorkflowDiagram::UnsupportedFormat
    end

    crate.identifier = ro_crate_identifier
    crate.url = ro_crate_url('ro_crate')

    workflow = is_a_version? ? self.parent : self
    merge_entities(crate, workflow) if workflow

    crate['isBasedOn'] = source_link_url if source_link_url && !crate['isBasedOn']
    crate['sdDatePublished'] = Time.now unless crate['sdDatePublished']
    crate['creativeWorkStatus'] = I18n.t("maturity_level.#{maturity_level}") if maturity_level

    # brute force deletion as I cannot track down where it comes from
    crate.contextual_entities.delete_if { |c| c['@id'] == '#ro-crate-preview.html' }
    crate
  end

  def merge_entities(crate, workflow)
    workflow_struct = Seek::BioSchema::Serializer.new(workflow).json_representation

    context = {
      '@vocab' => 'https://somewhere.com/'
    }
    workflow_struct['@context'] = context
    crate['name'] = "Research Object Crate for #{workflow_struct['name']}"
    crate['description'] = workflow_struct['description']

    workflow_struct.except!('encodingFormat')

    flattened = JSON::LD::API.flatten(workflow_struct, context)
    flattened.except!('@context')

    flattened['@graph'].each do |elem|
      type = elem['@type']
      type = [type] unless type.is_a?(Array)
      if type.include?('ComputationalWorkflow')
        merge_fields(crate.main_workflow, elem)
      else
        entity_class = ROCrate::ContextualEntity.specialize(elem)
        entity = entity_class.new(crate, elem['@id'], elem)
        crate.add_contextual_entity(entity)
      end
    end
  end
  
  def merge_fields(crate_workflow, bioschemas_workflow)
    bioschemas_workflow.each do |key, value|
      crate_workflow[key] = value unless crate_workflow[key]
    end
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
