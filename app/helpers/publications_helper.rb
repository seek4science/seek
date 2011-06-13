require 'doi_record'

module PublicationsHelper
  def people_by_project_options(projects, selected_person=nil, selected_project=nil)
    options = ""
    selected = false
    projects.each do |project|
      project_options = "<optgroup title=\"#{h project.title}\" label=\"#{h truncate(project.title)}\">"
      project.people.sort{|a,b| (a.last_name.nil? ? nil : a.last_name.capitalize) <=> (b.last_name.nil? ? nil : b.last_name.capitalize)}.each do |person|        
        #'select' this person if specified to be selected, and within this project group (once and only once)
        selected_text = ""
        if !selected && ((selected_project.nil? || (project == selected_project)) && (person == selected_person))
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

  def publication_type_text type
    if type==DoiRecord::PUBLICATION_TYPES[:conference]
      "Conference"
    elsif type == DoiRecord::PUBLICATION_TYPES[:book_chapter]
      "Book"
    else
      "Journal"
    end
  end
end
