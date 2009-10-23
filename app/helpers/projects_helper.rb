module ProjectsHelper
  def project_select_choices
    res=[]
    Project.find(:all).collect{|p| res << [p.name,p.id]}
    return res
  end

  def projects_link_list projects,sorted=true
    projects=projects.select{|p| !p.nil?} #remove nil items
    return "<span class='none_text'>Not defined</span>" if projects.empty?

    result=""
    projects=projects.sort{|a,b| a.title<=>b.title} if sorted
    projects.each do |proj|
      result += link_to h(proj.title),proj
      result += " | " unless projects.last==proj
    end
    return result
  end

  def pals_link_list project
    if project.pals.empty?
      "<span class='none_text'>No Pals for this project</span>";
    else
      project.pals.collect{|p| link_to(h(p.name),p)}.join(", ")
    end
  end
end
