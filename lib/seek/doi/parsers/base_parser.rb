module Seek
  module Doi
    module Parsers
        class BaseParser
        def parse(_doi)
          raise NotImplementedError, "#{self.class.name} must implement #parse"
        end

        protected

        def normalize_metadata(raw)
          {
            title: raw[:title],
            publication_authors: raw[:publication_authors],
            journal: raw[:journal],
            published_date: raw[:published_date],
            doi: raw[:doi],
            pubmed_id: raw[:pubmed_id],
            abstract: raw[:abstract],
            citation: raw[:citation],
            editor: raw[:editor],
            booktitle: raw[:booktitle],
            publisher: raw[:publisher],
            url: raw[:url]
          }.compact
        end
      end
    end
  end
end
