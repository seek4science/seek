class TreeviewBuilder
  include ImagesHelper
  include ActionView::Helpers::SanitizeHelper
  def initialize(project, folders)
    @project = project
    @folders = folders
  end

  SP_ADVANCED_ENABLED = Seek::Config.project_single_page_advanced_enabled
  BOLD = { 'style': 'font-weight:bold' }.freeze

  def build_tree_data
    study_items = []
    investigation_items = []

    @project.investigations.map do |investigation|
      investigation.studies.map do |study|
        assay_items = study.assays.map { |assay| build_assay_item(assay) }
        study_items << build_study_item(study, assay_items)
      end
      investigation_items << build_investigation_item(investigation, study_items)
      study_items = []
    end

    # Documents folder
    if Seek::Config.project_single_page_folders_enabled
    @folders.reverse_each.map { |f| investigation_items.unshift(folder_node(f)) } if @folders.respond_to? :each
    end
    sanitize(JSON[[build_project_item(@project, investigation_items)]])
  end

  private

  def folder_node(folder)
    children = folder.children.map { |child| folder_node(child) }
    obj = { id: "folder_#{folder.id}", text: folder.title, _type: 'folder', count: folder.count.to_s,
            children: children, folder_id: folder.id, project_id: folder.project.id, resource: folder }
    create_node(obj)
  end

  def create_node(obj)
    can_view = if obj[:resource].is_a?(SampleType)
                 obj[:resource].can_view?(User.current_user, nil, true)
               else
                 obj[:resource].can_view?
               end
    unless can_view
      obj[:text] = 'hidden item'
      obj[:a_attr] = { 'style': 'font-style:italic;font-weight:bold;color:#ccc' }
    end

    node = { id: obj[:id], text: obj[:text], a_attr: obj[:a_attr], count: obj[:count],
             data: { id: obj[:_id], type: obj[:_type], project_id: obj[:project_id], folder_id: obj[:folder_id] }, state: { opened: true, separate: { label: obj[:label] } }, children: obj[:children], icon: get_icon(obj[:resource]) }
    deep_compact(node)
  end

  def get_icon(resource)
    ActionController::Base.helpers.asset_path(resource_avatar_path(resource) ||
    icon_filename_for_key("#{resource.class.name.downcase}_avatar"))
  end

  def deep_compact(hash)
    hash.compact.transform_values do |value|
      next value unless value.instance_of?(Hash)

      deep_compact(value)
    end.reject { |_k, v| v.blank? }
  end

  def create_sample_node(sample_type)
    create_node({ text: 'samples', _type: 'sample', resource: Sample.new,	count: sample_type.samples.length,
                  _id: sample_type.id })
  end

  def isa_study_elements(study)
    return [] unless SP_ADVANCED_ENABLED

    elements = []
    if study.sample_types.any?
      elements << create_node({ text: 'Sources table', _type: 'source_table', _id: study.sample_types.first.id,
                                resource: study.sample_types.first, children: [create_sample_node(study.sample_types.first)] })
      if study.sops.present?
        elements << create_node({ text: 'Protocol', _type: 'study_protocol', _id: study.sops.first.id,
                                  resource: study.sops.first })
      end
      elements << create_node({ text: 'Samples table', _type: 'study_samples_table', _id: study.sample_types.second.id,
                                resource: study.sample_types.first, children: [create_sample_node(study.sample_types.second)] })
      elements << create_node({ text: 'Experiment overview', _type: 'study_experiment_overview', _id: study.id,
                                resource: study.sample_types.first })
    end

    elements
  end

  def isa_assay_elements(assay)
    return [] unless SP_ADVANCED_ENABLED

    elements = []
    if assay.sample_type.present?
      if assay.sops.any?
        elements << create_node({ text: 'Protocol', _type: 'assay_protocol', _id: assay.sops.first.id,
                                  resource: assay.sops.first })
      end
      elements << create_node({ text: 'Samples table', _type: 'assay_samples_table', _id: assay.sample_type.id,
                                resource: assay.sample_type, children: [create_sample_node(assay.sample_type)] })
      elements << create_node({ text: 'Experiment overview', _type: 'assay_experiment_overview', _id: assay.id,
                                resource: assay.sample_type })
    end

    elements
  end

  def build_project_item(_project, investigation_items)
    create_node({ text: @project.title, _type: 'project', _id: @project.id, a_attr: BOLD, label: 'Project',
                  children: investigation_items, resource: @project })
  end

  def build_investigation_item(investigation, study_items)
    create_node({ text: investigation.title, _type: 'investigation', _id: investigation.id, a_attr: BOLD,
                  label: 'Investigation', children: study_items, resource: investigation })
  end

  def build_study_item(study, assay_items)
    create_node({ text: study.title, _type: 'study', _id: study.id, a_attr: BOLD, label: 'Study',
                  children: isa_study_elements(study) + assay_items, resource: study })
  end

  def build_assay_item(assay)
    create_node({ text: assay.title, _type: 'assay', label: 'Assay', _id: assay.id, a_attr: BOLD,
                  children: isa_assay_elements(assay), resource: assay })
  end
end
