module StudiesHelper
  # generates the HTML to display the project avatar and named link
  def related_project_avatar(project)
    project_title = h(project.title)
    project_url = project_path(project)
    image_tag = avatar(project, 60, false, project_url, project_title, false)
    project_link = link_to project_title, project_url, alt: project_title

    (image_tag + "<p style='margin: 0; text-align: center;'>#{project_link}</p>").html_safe
  end

  def study_link(study)
    if study.nil?
      "<span class='none_text'>Not associated with a Study</span>".html_safe
    elsif study.can_view?
      link_to study.title, study
    else
      hidden_items_html [study]
    end
  end

  def authorised_studies(projects = nil)
    authorised_assets(Study, projects, 'view')
  end

  def show_batch_miappe_button?
    ExtendedMetadataType.where(supported_type: 'Study', title: ExtendedMetadataType::MIAPPE_TITLE, enabled: true).any?
  end

  # the selection dropdown box for selecting the study for a resource, such as assay or observation unit
  def resource_study_selection(element_name, current_study)
    grouped_options = grouped_options_for_study_selection(current_study)
    blank = current_study.blank? ? 'Not specified' : nil
    disabled = current_study && !current_study.can_edit?
    options = grouped_options_for_select(grouped_options, current_study.try(:id))
    select_tag(element_name, options,
               class: 'form-control', include_blank: blank, disabled: disabled).html_safe
  end
end
