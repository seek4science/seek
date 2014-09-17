module Seek
  module Data
    module BioSamplesExtraction
        include SysMODB::SpreadsheetExtractor

        def bio_samples_population institution_id=nil, to_populate=true
          begin
            if content_blob.is_extractable_spreadsheet?

              bio_samples = nil

              ActiveRecord::Base.transaction do
                begin
                  bio_samples = Seek::Data::BioSamples.new self, spreadsheet_xml, to_populate, institution_id
                rescue  Exception => e
                  bio_samples = Seek::Data::BioSamples.new self
                  bio_samples.errors = "Error parsing spreadsheet: #{e.message}"
                  #Rails.logger.error bio_samples.errors
                  raise ActiveRecord::Rollback
                end
              end
              bio_samples
            else
              Seek::Data::BioSamples.new self
            end
          rescue Exception => e
            Rails.logger.error("Error parsing spreadsheet #{e.message}")
            raise(e) if Rails.env=="test"
            bio_samples = Seek::Data::BioSamples.new self
            bio_samples.errors = "Error parsing spreadsheet: #{e.backtrace.join('<br/>')}"
            bio_samples
          end
        end
      end
  end
end