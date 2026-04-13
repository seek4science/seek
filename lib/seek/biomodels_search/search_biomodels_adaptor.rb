

module Seek
  module BiomodelsSearch
    class SearchBiomodelsAdaptor < AbstractSearchAdaptor

      NUMRESULTS = 25
      def perform_search(query)
        
        json = Rails.cache.fetch("biomodels/search/#{Digest::SHA256.hexdigest(query)}", expires_in: 1.day) do
          RestClient.get("https://www.ebi.ac.uk/biomodels/search?query=#{CGI.escape(query)}&numResults=#{NUMRESULTS}", accept: 'application/json').body
        end

        json = JSON.parse(json)
        json['models'].collect do |result|
          begin
            BiomodelsSearchResult.new result['id']
          rescue NoMethodError=>exception
            Seek::Errors::ExceptionForwarder.send_notification(exception, data: { error: 'error reading response from BioModels', item_id: result['id'], query: query })
            nil
          rescue BiomodelsSearchResult::ModelNotFoundError
            nil
          end
        end.compact.reject do |biomodels_result|
          biomodels_result.title.blank?
        end
      rescue StandardError => exception
        raise exception unless Rails.env.production?
        Seek::Errors::ExceptionForwarder.send_notification(exception, data: { query: query })
        []
      end

      def fetch_item(item_id)
        result = BiomodelsSearchResult.new item_id
        result.title.blank? ? nil : result
      end

      def supported?
        true
      end
    end

    class BiomodelsSearchResult < Struct.new(:authors, :abstract, :title, :published_date, :publication_id, :publication_title, :model_id, :last_modification_date, :main_filename, :unreleased)
      include Seek::ExternalSearchResult
      class ModelNotFoundError < StandardError; end
      alias_attribute :id, :model_id

      def initialize(model_id)
        self.authors = []
        self.model_id = model_id
        populate
      end

      def download_link
        "https://www.ebi.ac.uk/biomodels/model/download/#{model_id}?filename=#{main_filename}"
      end

      private

      def populate
        begin
          json = Rails.cache.fetch("biomodels_item_json_#{model_id}") do
            RestClient.get("https://www.ebi.ac.uk/biomodels/#{model_id}", accept: 'application/json').body
          end
        rescue RestClient::NotFound
          raise ModelNotFoundError, "Model with id #{model_id} not found in BioModels database"
        end

        json = JSON.parse(json)

        self.title = json['name']
        self.abstract = json['description']
        if json['firstPublished']
          self.publication_title = json.dig('publication', 'title')
          self.authors = (json.dig('publication', 'authors') || []).collect{|author| author['name'] }
          revisions = (json.dig('history', 'revisions') || []).sort_by{|rev| rev['version'] }
          first_version = revisions&.first
          latest_version = revisions&.last

          self.published_date = Time.at(first_version['submitted'].to_i) if first_version&.fetch('submitted')
          self.last_modification_date = Time.at(latest_version['submitted'].to_i) if latest_version&.fetch('submitted')

          self.main_filename = (json.dig('files','main') || []).first&.fetch('name')
          self.unreleased = false
        else
          self.unreleased = true
        end
      end
    end
  end
end
