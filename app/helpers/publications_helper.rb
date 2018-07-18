require 'doi/record'

module PublicationsHelper
  def author_to_person_options(selected_id, suggestion)
    projects = Project.includes(:people)
    grouped_options_for_select(projects.map { |p| [p.title, p.people.map { |m| ["#{m.name}#{' (suggested)' if suggestion == m}", m.id] }] },
                               selected_id || suggestion.try(:id))
  end

  def publication_type_text(type)
    if type == :conference
      'Conference'
    elsif type == :book_chapter
      'Book'
    else
      'Journal'
    end
  end

  def authorised_publications(projects = nil)
    authorised_assets(Publication, projects)
  end
end
