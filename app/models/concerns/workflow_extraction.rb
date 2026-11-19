require 'ro_crate'

module WorkflowExtraction
  PREVIEW_TEMPLATE = File.read(File.join(Rails.root, 'script', 'preview.html.erb'))

  extend ActiveSupport::Concern

  # How an uploaded RO-Crate is regenerated, when Seek::Config.regenerate_workflow_ro_crates is set:
  #   replace_all - SEEK's values replace those of the uploaded main workflow
  #   replace_seek - SEEK's values replace those of the uploaded main workflow that describe SEEK's record of it
  #                  (SEEK_RECORD_PROPERTIES), other properties are only added if missing
  #   fill_missing - SEEK's values are only added where the uploaded main workflow has none
  #   new_crate - a new crate holding the uploaded files, described only by SEEK
  RO_CRATE_REGENERATION_STRATEGIES = %w[replace_all replace_seek fill_missing new_crate].freeze

  SEEK_RECORD_PROPERTIES = %w[url identifier isBasedOn contributor producer creator license version dateCreated
                              dateModified sdPublisher].freeze

  # Properties of the main workflow that describe the crate's own structure, which are never replaced
  CRATE_STRUCTURE_PROPERTIES = %w[@id @type image subjectOf].freeze

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

  # Whether SEEK populates the crate with its own metadata. An uploaded RO-Crate is only populated if it is a basic
  # crate, or Seek::Config.regenerate_workflow_ro_crates is set, otherwise it is provided as it was uploaded.
  def should_generate_crate?
    is_basic_ro_crate? || !is_already_ro_crate? || Seek::Config.regenerate_workflow_ro_crates
  end

  # Whether this is an uploaded (not basic) RO-Crate that SEEK regenerates
  def regenerating_uploaded_crate?
    is_already_ro_crate? && !is_basic_ro_crate? && Seek::Config.regenerate_workflow_ro_crates
  end

  # The strategy for regenerating the crate, see RO_CRATE_REGENERATION_STRATEGIES. Crates that SEEK generates, or
  # basic crates, only have the missing properties added.
  def ro_crate_regeneration_strategy
    return 'fill_missing' unless regenerating_uploaded_crate?

    strategy = Seek::Config.workflow_ro_crate_regeneration_strategy
    RO_CRATE_REGENERATION_STRATEGIES.include?(strategy) ? strategy : 'replace_all'
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

  def can_run?(execution_base_url = nil)
    can_download?(nil) && workflow_class&.executable? && run_url(execution_base_url).present?
  end

  def run_url(execution_base_url = nil)
    if workflow_class&.key == 'galaxy'
      base = execution_base_url || execution_instance_url || Seek::Config.galaxy_instance_default
      return if base.nil?

      parent_id = is_a_version? ? parent.id : id
      url = URI(base) + 'workflows/trs_import'
      params = {
        trs_url: Seek::Util.routes.ga4gh_trs_v2_tool_version_url(parent_id, version_id: version),
        run_form: true
      }
      url.query = URI.encode_www_form(params)
      url.to_s
    end
  end

  def diagram_exists?
    path = Dir.glob(cached_diagram_path('*')).last
    path && File.exist?(path)
  end

  def diagram_generation_error?
    @diagram_generation_error = extractor.diagram_generation_error? if @diagram_generation_error.nil?
    @diagram_generation_error
  end

  def diagram
    path = Dir.glob(cached_diagram_path('*')).last

    unless path && File.exist?(path)
      e = extractor
      diagram = e.generate_diagram
      if diagram.nil? || diagram.length <= 1
        @diagram_generation_error = e.diagram_generation_error?
        return nil
      end
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
        crate.main_workflow = main_workflow_blob.to_crate_entity(crate, type: ROCrate::Workflow, properties: { contentUrl: content_url(m) })
        remotes.delete(main_workflow_blob.path)
        crate.main_workflow.programming_language = ROCrate::ContextualEntity.new(crate, nil, workflow_class&.ro_crate_metadata || Seek::WorkflowExtractors::Base::NULL_CLASS_METADATA)
      end

      d = diagram_blob
      if d
        remotes.delete(d.path)
        diagram_entity = d.to_crate_entity(crate, type: ROCrate::WorkflowDiagram, properties: { contentUrl: content_url(d) })
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
        cwl_entity = c.to_crate_entity(crate, type: ROCrate::WorkflowDescription, properties: { contentUrl: content_url(c) })
        crate.add_data_entity(cwl_entity)
        crate.main_workflow.cwl_description = cwl_entity if crate.main_workflow
      end

      remotes.each do |path, url|
        crate.add_external_file(url, localPath: path)
      end

      crate['datePublished'] = git_version.commit_object&.time
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
    crate.license = Seek::License.find(license)&.url
    crate.identifier = ro_crate_identifier
    crate.url = ro_crate_url('ro_crate')

    merge_entities(crate, self)

    crate['isBasedOn'] = source_link_url if source_link_url && !crate['isBasedOn']
    crate['datePublished'] = Time.now unless crate['datePublished']
    crate['sdDatePublished'] = Time.now unless crate['sdDatePublished']
    crate['creativeWorkStatus'] = I18n.t("maturity_level.#{maturity_level}") if maturity_level

    crate.preview.template = WorkflowExtraction::PREVIEW_TEMPLATE

    crate
  end

  def merge_entities(crate, workflow, strategy = ro_crate_regeneration_strategy)
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

    replaced_ids = []
    flattened['@graph'].each do |elem|
      type = elem['@type']
      type = [type] unless type.is_a?(Array)
      if type.include?('ComputationalWorkflow') && crate.main_workflow
        replaced_ids += merge_fields(crate.main_workflow, elem, strategy)
      else
        entity_class = ROCrate::ContextualEntity.specialize(elem)
        elem['@id'] = URI.decode_www_form_component(elem['@id'])
        entity = entity_class.new(crate, nil, elem)
        crate.add_contextual_entity(entity)
      end
    end

    remove_unlinked_entities(crate, replaced_ids)
  end

  # Adds the properties of the Bioschemas workflow to the crate's main workflow, replacing existing values according
  # to the strategy (see RO_CRATE_REGENERATION_STRATEGIES). A blank value never replaces an existing one.
  # Returns the ids of the entities that the replaced values referred to.
  def merge_fields(crate_workflow, bioschemas_workflow, strategy = 'fill_missing')
    replaced_ids = []
    bioschemas_workflow.each do |key, value|
      next if CRATE_STRUCTURE_PROPERTIES.include?(key)

      existing = crate_workflow[key]
      if existing.nil?
        crate_workflow[key] = value
      elsif value.present? && replace_field?(key, strategy)
        replaced_ids += Array.wrap(existing).filter_map { |v| v['@id'] if v.is_a?(Hash) }
        crate_workflow[key] = value
      end
    end
    replaced_ids
  end

  def replace_field?(key, strategy)
    case strategy
    when 'replace_all'
      true
    when 'replace_seek'
      SEEK_RECORD_PROPERTIES.include?(key)
    else
      false
    end
  end

  # Removes the contextual entities with the given ids that nothing in the crate links to any more
  def remove_unlinked_entities(crate, ids)
    entities = ids.uniq.filter_map { |id| crate.dereference(id) }
    return if entities.empty?

    crate.gc { |entity| entities.include?(entity) }
  end

  # A new crate holding the files of the uploaded crate in source_dir, but none of its metadata, other than which
  # files are the main workflow, its diagram and its CWL description.
  def new_crate_from_uploaded(uploaded, source_dir)
    crate = ROCrate::WorkflowCrate.new
    crate.add_all(source_dir, false, include_hidden: true)
    main = uploaded.main_workflow
    return crate unless main

    crate.main_workflow = ROCrate::Workflow.new(crate, uploaded_entity_source(main, source_dir), main.filepath)
    if (diagram = uploaded.main_workflow_diagram)
      crate.main_workflow.diagram = ROCrate::WorkflowDiagram.new(crate, uploaded_entity_source(diagram, source_dir),
                                                                diagram.filepath)
    end
    if (cwl = uploaded.main_workflow_cwl)
      crate.main_workflow.cwl_description = ROCrate::WorkflowDescription.new(crate, uploaded_entity_source(cwl, source_dir),
                                                                            cwl.filepath)
    end
    crate
  end

  def uploaded_entity_source(entity, source_dir)
    Pathname.new(File.join(source_dir, entity.filepath))
  end

  def ro_crate
    inner = proc do |crate|
      populate_ro_crate(crate) if should_generate_crate?

      if block_given?
        # TODO: Find a way to do this in populate_ro_crate (Without tmpdir disappearing when it comes to writing)
        if should_generate_crate? && is_git_versioned?
          git_version.in_temp_dir do |tmpdir|
            crate.entities.each do |entity|
              next unless !entity.nil? && entity.type == 'File' && entity.external? && !entity['localPath'].nil?

              full_path = File.join(tmpdir, entity['localPath'])
              File.delete(full_path) if File.zero?(full_path)
            end
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

    if is_already_ro_crate? && ro_crate_regeneration_strategy == 'new_crate'
      if is_git_versioned?
        # populate_ro_crate builds the crate from the git repository
        ROCrate::WorkflowCrate.new.tap(&inner)
      else
        extractor.open_crate { |uploaded, source_dir| inner.call(new_crate_from_uploaded(uploaded, source_dir)) }
      end
    elsif is_already_ro_crate?
      extractor.open_crate(&inner)
    else
      ROCrate::WorkflowCrate.new.tap(&inner)
    end
  end

  def ro_crate_zip
    ro_crate do |crate|
      path = ro_crate_path
      File.delete(path) if File.exist?(path)
      ROCrate::Writer.new(crate).write_zip(path)
    end

    ro_crate_path
  end

  def ro_crate_identifier
    doi.present? ? "https://doi.org/#{doi}" : ro_crate_url
  end

  def ro_crate_url(action = nil)
    resource = is_a_version? ? parent : self
    resource = [action.to_sym, resource] if action
    Seek::Util.routes.polymorphic_url(resource, version: version)
  end

  def content_url(blob)
    return unless is_git_versioned?

    return unless blob

    return blob.url if blob.remote? && blob.fetched?

    resource = is_a_version? ? parent : self
    Seek::Util.routes.polymorphic_url([resource, :git_download], version: version, path: blob.path)
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
        exist.path = path
        exist.save(validate: false) if exist.persisted?
        exist
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
