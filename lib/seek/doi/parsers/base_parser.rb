module Seek
  module Doi
    module Parsers
      class BaseParser
        def parse(_doi)
          raise NotImplementedError, "#{self.class.name} must implement #parse"
        end

        protected

        def build_struct(raw)
          OpenStruct.new(normalize_metadata(raw))
        end

        def normalize_metadata(raw)
          {
            title: raw[:title],
            authors: raw[:authors],
            journal: raw[:journal],
            date_published: raw[:date_published],
            doi: raw[:doi],
            abstract: raw[:abstract],
            citation: raw[:citation],
            editors: raw[:editors],
            booktitle: raw[:booktitle],
            publisher: raw[:publisher],
            url: raw[:url]
          }.compact
        end
      end
    end
  end
end
