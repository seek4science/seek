require 'doi_query_tool'

module Seek
  module Doi
    module Parsers
      class CrossrefParser < BaseParser
        def parse(doi)
          result = DOIQueryTool.fetch_metadata(doi)
          normalize_metadata(
            title: result.title,
            authors: result.authors,
            journal: result.journal,
            date: result.published,
            doi: doi,
            abstract: result.abstract,
            publisher: result.publisher,
            url: result.url
          )
        end
      end
    end
  end
end
