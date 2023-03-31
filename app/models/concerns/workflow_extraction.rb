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

  delegate :can_render_diagram?, :has_tests?, to: :extractor

  def is_git_ro_crate?
    is_git_versioned? && git_version.ro_crate?
  end

  def is_already_ro_crate?
    (!is_git_versioned? && content_blob.original_filename.end_with?('.crate.zip')) || is_git_ro_crate?
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

  def structure
    WorkflowInternals::Structure.new(internals)
  end

  delegate :inputs, :outputs, :steps, to: :structure

  def can_run?
    can_download?(nil) && workflow_class_title == 'Galaxy' && Seek::Config.galaxy_instance_trs_import_url.present?
  end

  def diagram_exists?
    path = Dir.glob(cached_diagram_path('*')).last
    path && File.exist?(path)
  end

  def diagram
    path = Dir.glob(cached_diagram_path('*')).last

    unless path && File.exist?(path)
      e = extractor
      diagram = e.generate_diagram
      return nil if diagram.nil? || diagram.length <= 1
      path = Pathname.new(cached_diagram_path(e.diagram_extension))
      path.parent.mkdir unless path.parent.exist?
      File.binwrite(path, diagram)
    end

    WorkflowDiagram.new(self, path.to_s)
  end

  def populate_ro_crate(crate)
    if is_git_versioned?
      remotes = git_version.remote_sources
      m = main_workflow_blob
      if m
        crate.main_workflow = main_workflow_blob.to_crate_entity(crate, type: ROCrate::Workflow)
        remotes.delete(main_workflow_blob.path)
        crate.main_workflow.programming_language = ROCrate::ContextualEntity.new(crate, nil, workflow_class&.ro_crate_metadata || Seek::WorkflowExtractors::Base::NULL_CLASS_METADATA)
      end

      d = diagram_blob
      if d
        remotes.delete(d.path)
        diagram_entity = d.to_crate_entity(crate, type: ROCrate::WorkflowDiagram)
        crate.add_data_entity(diagram_entity)
        crate.main_workflow.diagram = diagram_entity if crate.main_workflow
      else # Was the diagram generated?
        d = diagram
        if d&.exists?
          diagram_entity = d.to_crate_entity(crate)
          crate.add_data_entity(diagram_entity)
          crate.main_workflow.diagram = diagram_entity if crate.main_workflow
        end
      end

      c = abstract_cwl_blob
      if c
        remotes.delete(c.path)
        cwl_entity = c.to_crate_entity(crate, type: ROCrate::WorkflowDescription)
        crate.add_data_entity(cwl_entity)
        crate.main_workflow.cwl_description = cwl_entity if crate.main_workflow
      end

      remotes.each do |path, url|
        crate.add_external_file(url)
      end
    else
      unless crate.main_workflow
        crate.main_workflow = ROCrate::Workflow.new(crate, content_blob.filepath, content_blob.original_filename, contentSize: content_blob.file_size)
      end
      d = diagram
      if d&.exists?
        wdf = crate.main_workflow_diagram || ROCrate::WorkflowDiagram.new(crate, d.path, d.filename)
        wdf.content_size = d.size
        crate.main_workflow.diagram = wdf
      end
    end

    authors = creators.map { |person| crate.add_person(nil, person.ro_crate_metadata) }
    others = other_creators&.split(',')&.collect(&:strip)&.compact || []
    authors += others.map.with_index { |name, i| crate.add_person("creator-#{i + 1}", name: name) }
    crate.author = authors
    crate.license = license
    crate.identifier = ro_crate_identifier
    crate.url = ro_crate_url('ro_crate')

    merge_entities(crate, self)

    crate['isBasedOn'] = source_link_url if source_link_url && !crate['isBasedOn']
    crate['sdDatePublished'] = Time.now unless crate['sdDatePublished']
    crate['creativeWorkStatus'] = I18n.t("maturity_level.#{maturity_level}") if maturity_level

    crate.preview.template = WorkflowExtraction::PREVIEW_TEMPLATE

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
      if type.include?('ComputationalWorkflow') && crate.main_workflow
        merge_fields(crate.main_workflow, elem)
      else
        entity_class = ROCrate::ContextualEntity.specialize(elem)
        elem['@id'] = URI.decode_www_form_component(elem['@id'])
        entity = entity_class.new(crate, nil, elem)
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
        # TODO: Find a way to do this in populate_ro_crate (Without tmpdir disappearing when it comes to writing)
        if should_generate_crate? && is_git_versioned?
          git_version.in_temp_dir do |tmpdir|
            crate.add_all(tmpdir, false, include_hidden: true)
            yield crate
          end
        else
          yield crate
        end
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
    begin
      ro_crate do |crate|
        path = ro_crate_path
        File.delete(path) if File.exist?(path)
        ROCrate::Writer.new(crate).write_zip(path)
      end

      ro_crate_path
    rescue StandardError => e
      raise ::ROCrate::WriteException.new("Couldn't generate RO-Crate metadata.", e)
    end
  end

  def ro_crate_identifier
    doi.present? ? "https://doi.org/#{doi}" : ro_crate_url
  end

  def ro_crate_url(action = nil)
    resource = is_a_version? ? parent : self
    resource = [action.to_sym, resource] if action
    Seek::Util.routes.polymorphic_url(resource, version: version)
  end

  [:main_workflow, :diagram, :abstract_cwl].each do |type|
    s_type = type.to_s

    define_method("#{s_type}_annotation") do
      git_version.find_git_annotation(s_type)
    end

    define_method("#{s_type}_path") do
      git_version.send("#{s_type}_annotation")&.path
    end

    define_method("#{s_type}_path_changed?") do
      instance_variable_get(:"@#{s_type}_path_changed") || false
    end

    define_method("#{type}_path=") do |path|
      exist = git_version.send("#{type}_annotation")
      instance_variable_set(:"@#{s_type}_path_changed", !exist || (exist.path != path))

      if path.blank?
        if exist
          exist.destroy
        end

        return
      end

      if exist
        exist.update_attribute(:path, path)
      else
        git_version.git_annotations.build(key: s_type, path: path)
      end
    end

    define_method("#{s_type}_blob") do
      git_version.get_blob(git_version.send("#{s_type}_path"))
    end

  end

  def refresh_internals
    self.internals = extractor.metadata[:internals] || {}
  end

  private

  def ro_crate_path
    if is_git_versioned?
      File.join(Seek::Config.converted_filestore_path, "git_version_#{git_version.id}.crate.zip")
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

  def clear_cached_diagram
    FileUtils.rm(Dir.glob(cached_diagram_path('*')))
  end
end
