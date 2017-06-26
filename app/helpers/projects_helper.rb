# encoding: UTF-8
module ProjectsHelper
  def project_select_choices
    res = []
    Project.all.collect { |p| res << [p.name, p.id] }
    res
  end

  def link_list_for_role(role_text, role_members, type = 'project')
    if role_members.empty?
      html = "<span class='none_text'>No #{role_text.pluralize} for this #{t(type)}</span>"
    else
      html = role_members.select(&:can_view?).collect { |p| link_to(h(p.name), p) }.join(', ')
    end
    html.html_safe
  end

  def pals_link_list(project)
    link_list_for_role(t('pal'), project.pals)
  end

  def asset_housekeepers_link_list(project)
    link_list_for_role(t('asset_housekeeper'), project.asset_housekeepers)
  end

  def project_administrator_link_list(project)
    link_list_for_role(t('project_administrator'), project.project_administrators)
  end

  def gatekeepers_link_list(project)
    link_list_for_role(t('asset_gatekeeper'), project.asset_gatekeepers)
  end

  def project_coordinators_link_list(project)
    link_list_for_role('Project coordinator', project.project_coordinators)
  end

  def programme_link(project)
    if project.try(:programme).nil?
      html = "<span class='none_text'>This #{t('project')} is not associated with a #{t('programme')}</span>"
    else
      html = '<span>' + link_to(h(project.programme.title), project.programme) + '</span>'
    end
    html.html_safe
  end

  def project_mailing_list(project)
    if project.people.empty?
      html = "<span class='none_text'>No people in this #{t('project')}</span>"
    else
      html = '<span>' + mailing_list_links(project).join(';<br/>') + '</span>'
    end
    html.html_safe
  end

  def mailing_list_links(project)
    people = project.people.sort_by(&:last_name).select(&:can_view?)
    people.map do |p|
      link_to(h(p.name), p) + ' (' + p.email + ')'
    end
  end

  def can_create_projects?
    Project.can_create?
  end

  def project_administrators_input_box(project)
    project_role_input_box project, Seek::Roles::PROJECT_ADMINISTRATOR
  end

  def project_asset_gatekeepers_input_box(project)
    project_role_input_box project, Seek::Roles::ASSET_GATEKEEPER
  end

  def project_asset_housekeepers_input_box(project)
    project_role_input_box project, Seek::Roles::ASSET_HOUSEKEEPER
  end

  def project_pals_input_box(project)
    project_role_input_box project, Seek::Roles::PAL
  end

  def project_role_input_box(project, role)
    administrators = project.send(role.to_s.pluralize)
    members = project.people
    box = ''
    box << objects_input("project[#{role}_ids]", administrators, typeahead: { values: members.map { |p| { id: p.id, name: p.name, hint: p.email } } })
    box.html_safe
  end

  def project_membership_json(project)
    project.work_groups.map do |wg|
      wg.group_memberships.map do |gm|
        {
          id: gm.id.to_s,
          person: { id: gm.person_id.to_s, name: gm.person.name },
          institution: { id: gm.work_group.institution.id.to_s, title: gm.work_group.institution.title },
          leftAt: gm.time_left_at,
          cannotRemove: !gm.person_can_be_removed?
        }
      end
    end.flatten.to_json
  end

  # the id for the hidden select field that holds the selected projects
  def project_selector_id
    "#{controller_name.singularize}_project_ids"
  end

  def person_can_remove_themself?(person, project)
    return false unless person && project
  end

  def projects_grouped_by_programme(selected = nil)
    if Seek::Config.programmes_enabled
      array = Project.order(:title).to_a.group_by { |p| p.programme.try(:title) || 'Independent projects' }.each_value do |projects|
        projects.map! { |p| [p.title, p.id] }
      end.to_a

      grouped_options_for_select(array, selected)
    else
      options_for_select(Project.all.sort_by(&:title).map { |p| [p.title, p.id] }, selected)
    end
  end

  def project_lookup_json(resources)
    mapping = resources.map do |r|
      [r.id, r.projects.map { |p| { id: p.id, title: p.title } }]
    end

    Hash[mapping].to_json.html_safe
  end
end
