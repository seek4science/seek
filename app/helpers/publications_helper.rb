require 'doi/record'

module PublicationsHelper
  def author_to_person_options(selected_id, suggestion)
    projects = Project.includes(:people)
    grouped = projects.map do |p|
      [
          p.title,
          p.people.map {|m| ["#{m.name}#{' (suggested)' if !selected_id && suggestion == m}", m.id]}
      ]
    end

    grouped_options_for_select(grouped, selected_id || suggestion.try(:id))
  end

  def publication_registered_mode(mode)
    if mode == 1
      'by PubMed ID'
    elsif mode == 2
      'by DOI'
    elsif mode == 3
      'manually'
    elsif mode == 4
      'from a bibtex file'
    else
      `unknown`
    end
  end

  def authorised_publications(projects = nil)
    authorised_assets(Publication, projects)
  end

  def publication_type_text(type)

    case type
    when 1
      return 'Journal'
    when 2
      return 'Book'
    when 3
      return 'Booklet'
    when 4
      return 'InBook'
    when 5
      return 'InCollection'
    when 6
      return 'InProceedings'
    when 7
      return 'Manual'
    when 8
      return 'Masters Thesis'
    when 9
      return 'Misc'
    when 10
      return 'Phd Thesis'
    when 11
      return 'Proceedings'
    when 12
      return 'Tech report'
    when 13
      return 'Unpublished'
    else
      return nil
    end
  end

  def get_publication_type(article)
    str_begin = "@"
    str_end = "{"
    publication_name = article.to_s[/#{str_begin}(.*?)#{str_end}/m, 1]

    # http://bib-it.sourceforge.net/help/fieldsAndEntryTypes.php#Entries
    case publication_name
    when 'article'
      return 1
    when 'book'
      return 2
    when 'booklet'
      return 3
    when 'inbook'
      return 4
    when 'incollection'
      return 5
    when 'inproceedings'
      return 6
    when 'manual'
      return 7
    when 'mastersthesis'
      return 8
    when 'misc'
      return 9
    when 'phdthesis'
      return 10
    when 'proceedings'
      return 11
    when 'techreport'
      return 12
    when 'unpublished'
      return 13
    end
  end
end


