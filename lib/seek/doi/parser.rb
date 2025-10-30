require 'open-uri'
require 'json'

module Seek
  module Doi
    class Parser
      DOI_ENDPOINT = 'https://doi.org'.freeze

      def self.parse(doi)
        agency = get_doi_ra(doi)

        case agency
        when 'DataCite'
          Seek::Doi::Parsers::DataciteParser.new.parse(doi)
        when 'Crossref'
          Seek::Doi::Parsers::CrossrefParser.new.parse(doi)
        else
          raise Seek::Doi::RANotSupported, "DOI registration agency '#{agency}' is not supported."
        end
      rescue OpenURI::HTTPError => e
        # Handle RA resolution issues
        raise Seek::Doi::FetchException, "Error resolving DOI #{doi}: #{e.message}"
      rescue Seek::Doi::BaseException
        raise # Re-raise already handled domain exceptions
      rescue StandardError => e
        # Fallback for truly unexpected errors
        raise Seek::Doi::FetchException, "Unexpected error resolving DOI #{doi}: #{e.message}"
      end

      private_class_method def self.get_doi_ra(doi)
        url = "#{DOI_ENDPOINT}/ra/#{doi}"
        response = URI.open(url).read
        data = JSON.parse(response)
        ra = data.dig(0, 'RA')
        status = data.dig(0, 'status')

        case status
        when 'Invalid DOI'
          raise Seek::Doi::MalformedDOIException, "Invalid DOI format: #{doi}."
        when 'DOI does not exist'
          raise Seek::Doi::NotFoundException, "DOI does not exist: #{doi}."
        end
        raise Seek::Doi::NotFoundException, "No registration agency found for DOI #{doi}" if ra.blank?
        ra
      end
    end
  end
end
