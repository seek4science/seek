require 'doi_record'

module PublicationsHelper
  def people_by_project_options(projects)
    options = ""
    projects.each do |project|
      project_options = "<optgroup id=#{project.id} title=\"#{h project.title}\" label=\"#{h truncate(project.title)}\">"
      project.people.each do |person|
        project_options << "<option value=\"#{person.id}\" title=\"#{h person.name}\">#{h truncate(person.name)}</option>"
      end
      project_options << "</optgroup>"
      options += project_options unless project.people.empty?
    end
    return options.html_safe
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

  def authorised_publications projects=nil
    authorised_assets(Publication,projects)
  end

  def author_display_list publication
    if publication.publication_author_orders.empty?
       "<span class='none_text'>Not specified</span>".html_safe
    else
      author_list = []
      publication.publication_author_orders.sort_by(&:order).collect(&:author).each do |author|
        if author.kind_of?(Person) && author.can_view?
          author_list << link_to(get_object_title(author), show_resource_path(author))
        else
          author_list << h(author.first_name) + " " + h(author.last_name)
        end
      end
      author_list.join(', ').html_safe
    end
  end
end
