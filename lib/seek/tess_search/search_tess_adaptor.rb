module Seek
  module TessSearch

    include CountryCodes
    
    class SearchTessAdaptor < AbstractSearchAdaptor
      TESS_BASE_URL = "https://tess.elixir-europe.org"
      def perform_search(query)
        
        json = RestClient.get(TESS_BASE_URL + "/events.json_api?q=#{CGI.escape(query)}").body
        
        json = JSON.parse(json)
        json['data'].collect do |result|
          TessSearchResult.new result
        end.compact.reject do |tess_result|
          tess_result.title.blank?
        end
      rescue StandardError => exception
        raise exception if Rails.env.development?
        Seek::Errors::ExceptionForwarder.send_notification(exception, data: { query: query })
        []
      end

      def supported?
        true
      end
    end

    class TessSearchResult <
          Struct.new(:title, :id, :description, :url, :self_link, :address,
                     :city, :country, :start_date, :end_date)
      include Seek::ExternalSearchResult

      def initialize(event_json)
        self.id = event_json['id']
        self.title = event_json.dig('attributes', 'title')
        self.description = event_json.dig('attributes', 'description')
        self.url = event_json.dig('attributes', 'url')
        self.self_link = event_json.dig('links','self')
        self.address = event_json.dig('attributes', 'venue')
        self.city = event_json.dig('attributes', 'city')
        self.country = CountryCodes::code(event_json.dig('attributes', 'country'))
        self.start_date = event_json.dig('attributes', 'start')
        self.end_date = event_json.dig('attributes', 'end')
      end

      def download_link
        self.self_link
      end
    end
  end
end
