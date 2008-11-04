module WorkGroupsHelper
  def work_group_select_choices
    WorkGroup.find(:all).map{|wg| [wg.project.title+" at "+wg.institution.name,wg.id]}
  end
  
  WorkGroupOption = Struct.new(:id, :institution_name)
  
  class ProjectType 
    attr_reader :type_name, :options, :project
    attr_writer :options
    def initialize(name,project)
      @project=project
      @type_name=name
      @options = []
    end
    
    def <<(option)
      @options << option
    end
  end
  
  def work_group_groups_for_selection
#    
#    options = []
#    
#    
#    Project.find(:all).each do |proj|
#      projType = WorkGroupType.new(proj.title)
#      proj.institutions.each do |i|
#        projType << WorkGroupOption.new(i.id, i.name)
#      end
#      options << projType
#    end
    
    options = []
    projType=nil
    WorkGroup.find(:all, :order=>"project_id").each do |wg|
      if (projType.nil? or projType.project != wg.project)
        options << projType unless projType.nil?
        projType=ProjectType.new(wg.project.title, wg.project)
      end
      projType << WorkGroupOption.new(wg.id, wg.institution.name)
    end
    
    
    return options
    
  end
  
end
