module ProjectsHelper
  def project_select_choices
    res=[]
    Project.find(:all).collect { |p| res << [p.name, p.id] }
    return res
  end

  def projects_link_list projects,sorted=true
    projects=projects.select{|p| !p.nil?} #remove nil items
    return "<span class='none_text'>Not defined</span>".html_safe if projects.empty?

    result=""
    projects=projects.sort{|a,b| a.title<=>b.title} if sorted
    projects.each do |proj|
      result += link_to h(proj.title),proj
      result += " | " unless projects.last==proj
    end
    return result.html_safe
  end

  def pals_link_list project
    if project.pals.empty?
      html = "<span class='none_text'>No PALs for this project</span>";
    else
      html = project.pals.select(&:can_view?).collect { |p| link_to(h(p.name), p) }.join(", ")
    end
    html.html_safe
  end

  def asset_managers_link_list project
    if project.asset_managers.empty?
      html = "<span class='none_text'>No Asset Managers for this project</span>";
    else
      html = project.asset_managers.select(&:can_view?).collect { |p| link_to(h(p.name), p) }.join(", ")
    end
    html.html_safe
  end

  def project_managers_link_list project
    if project.project_managers.empty?
      html = "<span class='none_text'>No Project Managers for this project</span>";
    else
      html = project.project_managers.select(&:can_view?).collect { |p| link_to(h(p.name), p) }.join(", ")
    end
    html.html_safe
  end

  def gatekeepers_link_list project
    if project.gatekeepers.empty?
      html = "<span class='none_text'>No Gatekeepers for this project</span>";
    else
      html = project.gatekeepers.select(&:can_view?).collect { |p| link_to(h(p.name), p) }.join(", ")
    end
    html.html_safe
  end

  def project_mailing_list project
    if project.people.empty?
      html = "<span class='none_text'>No people in this project</span>";
    else
      html = "<span>" + project.people.sort_by(&:last_name).select(&:can_view?).map{|p|link_to(h(p.name), p) + " (" + p.email + ")"}.join(";<br/>") + "</span>";
    end
    html.html_safe
  end
end
