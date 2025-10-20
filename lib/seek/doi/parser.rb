require 'open-uri'
require 'json'

module Seek
  module Doi
    class Parser

      DOI_ENDPOINT = 'https://doi.org'.freeze
      def self.parse(doi)
        return if doi.blank?

        agency = get_doi_ra(doi)
        case agency
        when 'DataCite'
          Seek::Doi::Parsers::DataCiteParser.new.parse(doi)
        when 'Crossref'
          Seek::Doi::Parsers::CrossrefParser.new.parse(doi)
        else
          Rails.logger.warn("Unsupported DOI registration agency: #{agency}")
          {}
        end
      rescue StandardError => e
        Rails.logger.error("DOI parsing failed for #{doi}: #{e.message}")
        {}
      end

      private_class_method def self.get_doi_ra(doi)
        prefix = doi.split('/').first
        url = DOI_ENDPOINT+"/ra/#{prefix}"
        data = JSON.parse(URI.open(url).read)
        data.dig(0, 'RA') # => "DataCite", "Crossref", etc.
      rescue StandardError => e
        Rails.logger.warn("Could not determine RA for DOI #{doi}: #{e.message}")
        nil
      end
    end
  end
end
