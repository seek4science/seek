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
    if mode == Publication::REGISTRATION_BY_PUBMED
      'by PubMed ID'
    elsif mode == Publication::REGISTRATION_BY_DOI
      'by DOI'
    elsif mode == Publication::REGISTRATION_MANUALLY
      'manually'
    elsif mode == Publication::REGISTRATION_FROM_BIBTEX
      'imported from a bibtex file'
    else
      `unknown`
    end
  end

  def authorised_publications(projects = nil)
    authorised_assets(Publication, projects)
  end

  def mini_file_soft_delete_icon(fileinfo, user)
    item_name = text_for_resource fileinfo
    if fileinfo.can_delete?(user)
      html = content_tag(:div) { image_tag_for_key('destroy', polymorphic_path([fileinfo.asset], action: :soft_delete_fulltext, code: params[:code]), "Delete #{item_name}", { data: { confirm: 'It cannot be undone. Are you sure?' }, action: :soft_delete_fulltext }, "Delete (cannot be reverted)") }
      return html.html_safe
    elsif fileinfo.can_manage?(user)
      explanation = unable_to_delete_text fileinfo
      html = "<li><span class='disabled_icon disabled' onclick='javascript:alert(\"#{explanation}\")' data-tooltip='#{tooltip(explanation)}' >" + image('destroy', alt: 'Delete', class: 'disabled') + " Delete (cannot be reverted) </span></li>"
      return html.html_safe
    end
  end

  def publication_authors_form_field(element_name, publication, allow_new: true, limit: nil)
    existing_objects = publication.publication_authors.map do |pa|
      full_name = [pa.first_name, pa.last_name].compact.join(" ")
      Struct.new(:id, :title).new(full_name, full_name)
    end

    typeahead = {
      handlebars_template: 'typeahead/publication_author',
      query_url: typeahead_publication_authors_publications_path
    }

    options = {
      typeahead: typeahead,
      limit: limit,
      allow_new: allow_new,
      class: 'form-control',
      'data-role': 'seek-objectsinput'
    }

    objects_input(element_name, existing_objects, options)
  end

end


