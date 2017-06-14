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

  def studies_link_list(studies, sorted = true)
    # FIXME: make more generic and share with other model link list helper methods
    return "<span class='none_text'>Not associated with any #{t('study').pluralize}</span>".html_safe if studies.empty?

    result = ''
    studies = studies.sort_by(&:title) if sorted
    studies.each do |study|
      if study.can_view?
        result += link_to study.title.capitalize, study
      else
        result += hidden_items_html [study]
      end
      result += ' | ' unless studies.last == study
    end
    result.html_safe
  end

  def authorised_studies(projects = nil)
    authorised_assets(Study, projects, 'view')
  end
end
