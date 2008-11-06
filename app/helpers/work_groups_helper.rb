module WorkGroupsHelper
  def work_group_select_choices
    WorkGroup.find(:all).map{|wg| [wg.project.title+" at "+wg.institution.name,wg.id]}
  end
  
  WorkGroupOption = Struct.new(:id, :institution_name)
  
  class ProjectType 
    attr_reader :project_name, :options, :project
    attr_writer :options
    def initialize(project)
      @project=project
      @project_name=project.title
      @options = []
    end
    
    def <<(option)
      @options << option
    end
  end
  
  def work_group_groups_for_selection
    
    options = []
    proj_type=nil
    work_groups = WorkGroup.find(:all)
    work_groups=work_groups.sort_by{|wg| wg.project.title }
    work_groups.each do |wg|
      if (proj_type.nil? or proj_type.project != wg.project)
        options << proj_type unless proj_type.nil?
        proj_type=ProjectType.new(wg.project)
      end
      proj_type << WorkGroupOption.new(wg.id, wg.institution.name)
    end
    
    options << proj_type unless proj_type.nil?
 
    return options   
  end
  
end
