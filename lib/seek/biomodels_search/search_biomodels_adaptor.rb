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
            biomodels_search_results.collect do |result|
              r=BiomodelsSearchResult.new result
            end.compact.to_yaml
          end
          YAML::load(yaml)
      end

    end

    class BiomodelsSearchResult < Struct.new(:authors, :abstract, :title, :published_date, :pubmed_id, :model_id, :last_modification_date)

      include Seek::ExternalSearchResult


      def initialize biomodels_search_result
        self.authors = []
        self.model_id=biomodels_search_result[:model_id]
        self.last_modification_date=biomodels_search_result[:last_modification_date]
        populate biomodels_search_result[:publication_id]
      end

      private

      def populate pubmed_id
        self.pubmed_id = pubmed_id
        query_result = Rails.cache.fetch("pubmed_fetch_#{pubmed_id}",:expires_in=>1.week) do
          begin
            result = Bio::MEDLINE.new(Bio::PubMed.efetch(pubmed_id).first).reference
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

    end

  end

end