require 'json'
require 'rest-client'

module Ebi
  class OlsClient

    ROOT_URL = 'https://www.ebi.ac.uk/ols4'.freeze
    API_ROOT_URL = "#{ROOT_URL}/api".freeze

    def all_descendants(ontology_id, term_iri)
      Rails.cache.fetch("ebi_ontology_terms_#{ontology_id}_#{term_iri}") do
        url = "#{API_ROOT_URL}/ontologies/#{ontology_id}/terms/#{double_url_encode(term_iri)}"

        self_json = JSON.parse(RestClient.get(url, accept: :json))
        @collected_iris = []
        all_children(self_json)
      end
    end

    def all_children(term_json, parent_iri = nil)
      @collected_iris << term_json['iri']
      term = { iri: term_json['iri'],
               label: term_json['label'],
               description: term_json['description'] }

      term[:parent_iri] = parent_iri if parent_iri

      url = "#{API_ROOT_URL}/ontologies/#{term_json['ontology_name']}/terms/#{double_url_encode(term_json['iri'])}/children"
      child_terms = []

      if term_json['has_children']
        loop do
          Rails.logger.debug("[OLS] Fetching #{url}...")
          j = JSON.parse(RestClient.get(url, accept: :json))
          child_terms += (j.dig('_embedded', 'terms') || [])
          url = j.dig('_links', 'next', 'href')
          break unless url
        end
      end

      terms = [term]

      child_terms.each do |child_json|
        next if @collected_iris.include?(child_json['iri'])

        terms += all_children(child_json, term_json['iri'])
      end

      terms
    end

    def self.ontologies
      return @ontologies if @ontologies

      ontology_list = begin
        Rails.cache.fetch('ebi_ontology_options') do
          JSON.parse(RestClient.get("#{API_ROOT_URL}/ontologies?size=1000",
                                    accept: :json))
        end
      rescue StandardError
        nil
      end

      ontology_list ||= JSON.parse(File.read(Rails.root.join('config', 'ontologies', 'ebi_ontologies.json')))

      @ontologies = ontology_list.dig('_embedded', 'ontologies')
    end

    # processes the JSON to return [ [title, namespace], ... ] filtering any without a title
    def self.ontology_choices
      opts = ontologies.map { |ontology| [ontology.dig('config', 'title'), ontology.dig('config', 'namespace')] }

      opts.sort_by { |o| o[0] || '' }.delete_if{|o| o[0].blank? }
    end

    def self.ontology_keys
      @ontology_keys ||= ontologies.map { |ontology| ontology.dig('config', 'namespace') }.sort.compact
    end

    private

    def double_url_encode(id)
      CGI.escape(CGI.escape(id)) # Yes this is correct
    end
  end
end
