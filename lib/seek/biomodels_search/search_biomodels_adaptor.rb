

module Seek
  module BiomodelsSearch
    class SearchBiomodelsAdaptor < AbstractSearchAdaptor
      NUMRESULTS=25
      def perform_search(query)
        #yaml = Rails.cache.fetch("biomodels_search_#{CGI.escape(query)}", expires_in: 1.day) do
          results = RestClient.get("https://www.ebi.ac.uk/biomodels/search?query=#{CGI.escape(query)}&numResults=#{NUMRESULTS}", accept: 'application/json') do |resp|
            json = JSON.parse(resp.body)
            json['models'].collect do |result|
              r = BiomodelsSearchResult.new result['id']
            end.compact.select do |biomodels_result|
              !biomodels_result.title.blank?
            end
          end
        yaml = results.to_yaml
        #end
        YAML.load(yaml)
      end

      def fetch_item(item_id)
        result = BiomodelsSearchResult.new item_id
        result = result.title.blank? ? nil : result
        YAML.load(result.to_yaml)
      end
    end

    class BiomodelsSearchResult < Struct.new(:authors, :abstract, :title, :published_date, :publication_id, :publication_title, :model_id, :last_modification_date)
      include Seek::ExternalSearchResult

      alias_attribute :id, :model_id

      def initialize(model_id)
        self.authors = []
        self.model_id = model_id
        populate
      end

      private

      def populate
        RestClient.get("https://www.ebi.ac.uk/biomodels/#{self.model_id}",accept:'application/json') do |resp|
          json = JSON.parse(resp.body)
          self.title = json['name']
          self.publication_title=json['publication']['title']
          self.abstract = json['description']
          self.authors = json['publication']['authors'].collect{|author| author['name']}
          self.published_date = Time.at(json['firstPublished']/1000)
          latest_version = json['history']['revisions'].sort{|rev| rev['version']}.first
          self.last_modification_date = Time.at(latest_version['submitted']/1000)
        end
      end

    end
  end
end
