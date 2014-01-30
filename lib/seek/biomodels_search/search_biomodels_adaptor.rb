require 'search_biomodel'

module Seek
  module BiomodelsSearch

    class SearchBiomodelsAdaptor < AbstractSearchAdaptor

      def perform_search query
          yaml = Rails.cache.fetch("biomodels_search_#{URI::encode(query)}",:expires_in=>1.day) do
            connection = SysMODB::SearchBiomodel.instance
            biomodels_search_results = connection.models(query).select do |result|
              !(result.nil? || result[:publication_id].nil?)
            end
            results = biomodels_search_results.collect do |result|
              r=BiomodelsSearchResult.new result
            end.compact.select do |biomodels_result|
              !biomodels_result.title.blank?
            end
            results.to_yaml

          end
          YAML::load(yaml)
      end

    end

    class BiomodelsSearchResult < Struct.new(:authors, :abstract, :title, :published_date, :publication_id, :model_id, :last_modification_date)

      include Seek::ExternalSearchResult
      include Seek::BioExtension

      def initialize biomodels_search_result
        self.authors = []
        self.model_id=biomodels_search_result[:model_id]
        self.last_modification_date=biomodels_search_result[:last_modification_date]
        self.publication_id = biomodels_search_result[:publication_id]
        populate
      end

      private

      def populate
        if publication_id_is_doi?

        else
          populate_from_pubmed
        end
      end

      def populate_from_pubmed
        query_result = Rails.cache.fetch("pubmed_fetch_#{self.publication_id}",:expires_in=>1.week) do
          begin
            result = Bio::MEDLINE.new(Bio::PubMed.efetch(self.publication_id).first).reference
          rescue Exception=>e
            result = Bio::MEDLINE.new("").reference
          end
          hash = {}
          hash[:abstract]=result.abstract
          hash[:title]=result.title
          hash[:published_date]=result.published_date
          hash[:authors]=result.authors.collect{|a| a.name.to_s}
          hash
        end
        self.abstract = query_result[:abstract]
        self.published_date = query_result[:published_date]
        self.title = query_result[:title]
        self.authors = query_result[:authors]
      end

      def publication_id_is_doi?
        self.publication_id.include?(".")
      end

    end

  end

end