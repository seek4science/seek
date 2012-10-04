require 'simple-spreadsheet-extractor'

module Seek
  module Data
    module TreatmentExtraction

      include SysMODB::SpreadsheetExtractor

      #returns an instance of Seek::Treatment, populated according to the contents of the spreadsheet if it matches a known template
      def treatments
        begin
          if content_blob.is_extractable_spreadsheet?
            xml = spreadsheet_xml
            Seek::Data::Treatments.new xml
          else
            Seek::Data::Treatments.new
          end
        rescue Exception => e
          Rails.logger.error("Error reading spreadsheet #{e.message}")
          raise(e) if Rails.env=="test"
          Seek::Data::Treatments.new
        end
      end
    end
  end
end