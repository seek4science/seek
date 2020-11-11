require 'json'
require 'rest-client'

module Ebi
  class OlsClient
    def all_descendants(ontology_id, term_iri)
      url = "https://www.ebi.ac.uk/ols/api/ontologies/#{ontology_id}/terms/#{double_url_encode(term_iri)}"

      self_json = JSON.parse(RestClient.get(url, accept: :json))
      @collected_iris = []
      all_children(self_json)
    end

    def all_children(term_json, parent_iri = nil)
      @collected_iris << term_json['iri']
      term = { iri: term_json['iri'],
               label: term_json['label'] }

      term[:parent_iri] = parent_iri if parent_iri

      url = "https://www.ebi.ac.uk/ols/api/ontologies/#{term_json['ontology_name']}/terms/#{double_url_encode(term_json['iri'])}/children"
      child_terms = []

      if term_json['has_children']
        loop do
          Rails.logger.info("[OLS] Fetching #{url}...")
          j = JSON.parse(RestClient.get(url, accept: :json))
          child_terms += (j.dig('_embedded', 'terms') || [])
          url = j.dig('_links', 'next', 'href')
          break unless url
        end
      end

      terms = [term]

      child_terms.each do |child_json|
        next if @collected_iris.include?(child_json['iri'])
        terms << all_children(child_json, term_json['iri'])
      end

      terms
    end

    private

    def double_url_encode(id)
      CGI.escape(CGI.escape(id)) # Yes this is correct
    end
  end
end