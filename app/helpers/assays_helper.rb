module AssaysHelper
  # the text shown in the association dropdown box. Includes the study to avoid ambiguity between similar named assays
  def assay_selection_dropdown_text(assay, select_truncate_length = 120)
    truncate(assay.title.html_safe, length: select_truncate_length)
  end

  def assay_organism_list_item(assay_organism)
    result = link_to assay_organism.organism.title, assay_organism.organism
    if assay_organism.strain
      result += ' : '
      result += link_to h(assay_organism.strain.info), assay_organism.strain, class: 'strain_info'
    end

    if assay_organism.tissue_and_cell_type
      result += ' : '
      result += link_to h(assay_organism.tissue_and_cell_type.title), assay_organism.tissue_and_cell_type, class: 'assay_tissue_and_cell_type_info'
    end

    if assay_organism.culture_growth_type
      result += " (#{assay_organism.culture_growth_type.title})"
    end
    result.html_safe
  end

  def list_assay_organisms(attribute, assay_organisms, html_options = {})
    result = "<p class='#{html_options[:class]}' id='#{html_options[:id]}'> <b>#{attribute}</b>: "

    result += assay_organisms.collect { |ao| assay_organism_list_item(ao) }.join(', ').html_safe
    result += '</p>'

    result.html_safe
  end

  # the selection dropdown box for selecting the study for an assay
  def assay_study_selection(current_study, form)
    grouped_options = grouped_options_for_study_selection(current_study)
    blank = current_study.blank? ? 'Not specified' : nil
    disabled = current_study && !current_study.can_edit?
    form.select(:study_id, grouped_options_for_select(grouped_options, current_study.try(:id)),
                { include_blank: blank }, class: 'form-control', disabled: disabled
               ).html_safe
  end

  # options for grouped_option_for_select, for building the select box for assay->study selection, grouped by investigation
  def grouped_options_for_study_selection(current_study)
    investigation_map = selectable_studies_mapped_to_investigation(current_study)
    investigation_map.keys.collect do |investigation|
      title = investigation.can_view? ? h(investigation.title) : "#{t('investigation')} title is hidden"
      [title, investigation_map[investigation].collect { |study| [h(study.title), study.id] }]
    end
  end

  # returns a map of the studies that can be selected, grouped by investigation
  # this includes the editable studies, plus the current associated study if it is not already included (i.e not edtiable)
  def selectable_studies_mapped_to_investigation(current_study)
    studies = Study.all_authorized_for(:edit)
    studies << current_study if current_study && !current_study.can_edit?
    investigation_map = {}
    studies.each do |study|
      investigation_map[study.investigation] ||= []
      investigation_map[study.investigation] << study
    end
    investigation_map
  end

  def authorised_assays(projects = nil, action = 'edit')
    authorised_assets(Assay, projects, action)
  end

  def direction_options
    dirs = [AssayAsset::Direction::NODIRECTION,
            AssayAsset::Direction::INCOMING,
            AssayAsset::Direction::OUTGOING]

    options_for_select(dirs.map { |dir| [direction_name(dir), dir] })
  end

  def direction_name(direction)
    case direction
    when AssayAsset::Direction::INCOMING
      'Incoming'
    when AssayAsset::Direction::OUTGOING
      'Outgoing'
    else
      'No direction'
    end
  end
end
