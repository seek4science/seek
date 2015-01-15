module Seek
  module Data
    # A mixin for DataFiles to handle aspects of data file extraction

    module DataFileExtraction
      include Seek::Data::TreatmentExtraction
      include Seek::Data::BioSamplesExtraction
      # include Seek::Data::SearchExtraction

      def contains_extractable_spreadsheet?
        content_blob.is_extractable_spreadsheet?
      end
    end
  end
end
