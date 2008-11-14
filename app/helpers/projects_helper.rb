module ProjectsHelper
  def project_select_choices
    res=[]
    Project.find(:all).collect{|p| res << [p.name,p.id]}
    return res
  end
end
