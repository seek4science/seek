require 'search_biomodel'

module Seek
  module BiomodelsSearch

    class SearchBiomodelsAdaptor < AbstractSearchAdaptor

      def perform_search query
        if !Seek::Config.pubmed_api_email.blank?
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
        else
          Rails.logger.warn("Pubmed email not defined, so skipping biomodels search")
          []
        end
      end

    end

    class BiomodelsSearchResult < Struct.new(:authors, :abstract, :title, :date_published, :pubmed_id, :tab, :model_id, :last_modification_date, :partial_path)

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
          result = PubmedQuery.new("seek@sysmo-db.org", Seek::Config.pubmed_api_email).fetch(pubmed_id)
          hash = {}
          hash[:abstract]=result.abstract
          hash[:title]=result.title
          hash[:date_published]=result.date_published
          hash[:authors]=result.authors.collect{|a| a.name.to_s}
          hash
        end
        self.abstract = query_result[:abstract]
        self.date_published = query_result[:date_published]
        self.title = query_result[:title]
        self.authors = query_result[:authors]
      end

    end

  end

end