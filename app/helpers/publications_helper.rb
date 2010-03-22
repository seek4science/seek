module PublicationsHelper
  def people_by_project_options(selected_person_id=nil, project_id=nil)
    options = ""
    selected = false
    Project.all.each do |project|
      project_options = "<optgroup title=\"#{h project.title}\" label=\"#{h truncate(project.title)}\">"
      project.people.each do |person|        
        #'select' this person if specified to be selected, and within this project group (once and only once)
        selected_text = ""
        if !selected && ((project_id.nil? || (project.id == project_id)) && (person.id == selected_person_id))
          selected_text = "selected=\"selected\""
          selected = true
        end
        project_options << "<option #{selected_text} value=\"#{person.id}\" title=\"#{h person.name}\">#{h truncate(person.name)}</option>"          
      end
      project_options << "</optgroup>"
      options += project_options unless project.people.empty?
    end   
    return options
  end  
end
