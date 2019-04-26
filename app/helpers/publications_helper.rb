require 'doi/record'

module PublicationsHelper
  def author_to_person_options(selected_id, suggestion)
    projects = Project.includes(:people)
    grouped = projects.map do |p|
      [
          p.title,
          p.people.map { |m| ["#{m.name}#{' (suggested)' if !selected_id && suggestion == m}", m.id] }
      ]
    end

    grouped_options_for_select(grouped,  selected_id || suggestion.try(:id))
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

  def publication_registered_mode(mode)
    if mode == 1
      'by PubMed ID'
    elsif mode == 2
      'by DOI'
    elsif mode == 3
      'manually'
    elsif mode == 4
      'from bibtex file'
    else
      `unknown`
    end
  end

  def authorised_publications(projects = nil)
    authorised_assets(Publication, projects)
  end
end


def fetch_pubmed_or_doi_result(pubmed_id, doi)
  result = nil
  @error = nil
  if pubmed_id
    begin
      result = Bio::MEDLINE.new(Bio::PubMed.efetch(pubmed_id).first).reference
      @error = result.error
    rescue => exception
      raise exception unless Rails.env.production?
      result ||= Bio::Reference.new({})
      @error = 'There was a problem contacting the PubMed query service. Please try again later'
      Seek::Errors::ExceptionForwarder.send_notification(exception, data: { message: "Problem accessing ncbi using pubmed id #{pubmed_id}" })
    end
  elsif doi
    begin
      query = DOI::Query.new(Seek::Config.crossref_api_email)
      result = query.fetch(doi)
      @error = 'Unable to get result' if result.blank?
      @error = 'Unable to get DOI' if result.title.blank?
    rescue DOI::MalformedDOIException
      @error = 'The DOI you entered appears to be malformed.'
    rescue DOI::NotFoundException
      @error = 'The DOI you entered could not be resolved.'
    rescue RuntimeError => exception
      @error = 'There was an problem contacting the DOI query service. Please try again later'
      Seek::Errors::ExceptionForwarder.send_notification(exception, data:{ message: "Problem accessing crossref using DOI #{doi}" })
    end
  end
  result
end