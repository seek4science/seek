module WorkGroupsHelper
  def work_group_select_choices
    WorkGroup.find(:all).map{|wg| [wg.project.title+" at "+wg.institution.name,wg.id]}
  end
end
