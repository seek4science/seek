module WorkGroupsHelper
  def work_group_select_choices
    WorkGroup.find(:all).map{|wg| [wg.project.name+" at "+wg.institution.name,wg.id]}
  end
  
  WorkGroupOption = Struct.new(:id, :institution_name)
  
  class ProjectType 
    attr_reader :project_name, :options, :project
    attr_writer :options
    def initialize(project)
      @project=project
      @project_name=project.name
      @options = []
    end
    
    def <<(option)
      @options << option
    end
  end
  
  def work_group_groups_for_selection
    
    options = []
    last_project=nil
    #if current_user is project manager and not admin, load work_groups of projects he is in
    if project_manager_logged_in? && !admin_logged_in?
      work_groups = current_user.person.projects.collect(&:work_groups).flatten
    else
      work_groups = WorkGroup.find(:all,:include=>[:project,:institution])
    end


    work_groups = work_groups.sort do |a,b|
      x=a.project.name <=> b.project.name
      x=a.institution.name <=> b.institution.name if x.zero?
      x
    end
    
    work_groups.each do |wg|
      if (last_project.nil? or last_project.project != wg.project)
        options << last_project unless last_project.nil?
        last_project=ProjectType.new(wg.project)
      end
      last_project << WorkGroupOption.new(wg.id, wg.institution.name)
    end
    
    options << last_project unless last_project.nil?

    no_project = Project.new(:name => 'No Projects')
    last_no_project = ProjectType.new(no_project)
    last_no_project << WorkGroupOption.new(nil, 'No Institutions')
    options.insert(0, last_no_project)
 
    return options   
  end
  
end
