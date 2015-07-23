# encoding: UTF-8
module ProjectsHelper
  def project_select_choices
    res=[]
    Project.all.collect { |p| res << [p.name, p.id] }
    return res
  end

  def projects_link_list projects,sorted=true
    projects=projects.select{|p| !p.nil?} #remove nil items
    return "<span class='none_text'>Not defined</span>".html_safe if projects.empty?

    result=""
    projects=projects.sort{|a,b| a.title<=>b.title} if sorted
    projects.each do |proj|
      result += link_to proj.title,proj
      result += " | " unless projects.last==proj
    end
    return result.html_safe
  end

  def link_list_for_role role_text, role_members
    if role_members.empty?
      html = "<span class='none_text'>No #{role_text.pluralize} for this #{t('project')}</span>";
    else
      html = role_members.select(&:can_view?).collect { |p| link_to(h(p.name), p) }.join(", ")
    end
    html.html_safe
  end

  def pals_link_list project
    link_list_for_role("PAL",project.pals)
  end

  def asset_managers_link_list project
    link_list_for_role("Asset Manager",project.asset_managers)
  end

  def project_administrator_link_list project
    link_list_for_role("#{t('project')} Administrator",project.project_administrator)
  end

  def gatekeepers_link_list project
    link_list_for_role("Gatekeeper",project.gatekeepers)
  end

  def project_coordinators_link_list project
    link_list_for_role("Project coordinator",project.project_coordinators)
  end
  
  def programme_link project
    if project.try(:programme).nil?
      html = "<span class='none_text'>This #{t('project')} is not associated with a #{t('programme')}</span>"
    else
      html = "<span>" + link_to(h(project.programme.title),project.programme) + "</span>"
    end
    html.html_safe
  end

  def project_mailing_list project
    if project.people.empty?
      html = "<span class='none_text'>No people in this #{t('project')}</span>";
    else
      html = "<span>" + mailing_list_links(project).join(";<br/>") + "</span>";
    end
    html.html_safe
  end

  def mailing_list_links project
    people = project.people.sort_by(&:last_name).select(&:can_view?)
    people.map do |p|
      link_to(h(p.name), p) + " (" + p.email + ")"
    end
  end

  def can_create_projects?
    Project.can_create?
  end


end
