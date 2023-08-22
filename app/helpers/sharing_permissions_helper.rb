module SharingPermissionsHelper

  def get_permission_type (permission)
    option = { target: :_blank }
    m = permission.contributor
    case permission.contributor_type
    when Permission::WORKGROUP
      institution = Institution.find(m.institution_id)
      project = Project.find(m.project_id)
      p_type = "#{link_to(h(project.title), project, option)}  @  #{link_to(h(institution.title), institution, option)}"
    when Permission::PERSON
      p_type = "#{link_to(h(m.title), m, option)}"
    else
      p_type = "#{permission.contributor_type}  #{link_to(h(m.title), m, option)}"
    end
    p_type.html_safe
  end

end
