module StudiesHelper
  # generates the HTML to display the project avatar and named link
  def related_project_avatar(project)
    project_title = h(project.title)
    project_url = project_path(project)
    image_tag = avatar(project, 60, false, project_url, project_title, false)
    project_link = link_to project_title, project_url, alt: project_title

    (image_tag + "<p style='margin: 0; text-align: center;'>#{project_link}</p>").html_safe
  end

  def sorted_measured_items
    items = MeasuredItem.all
    items.sort_by(&:title)
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
    CustomMetadataType.where(supported_type: 'Study', title: 'MIAPPE metadata').any?
  end
end
