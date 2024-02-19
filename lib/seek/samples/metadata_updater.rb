module Seek
  module Samples

    class SampleMetadataUpdateException < StandardError; end

    # Class to handle the updating of sample metadata after updating Sample type
    class MetadataUpdater
      def initialize(sample_type)
        @sample_type = sample_type
      end

      def update_metadata
        samples = @sample_type.samples
        sample_attributes = @sample_type.sample_attributes.map(&:title)

        samples.each do |sample|
          metadata = JSON.parse(sample.json_metadata)
          missing_attributes = sample_attributes - metadata.keys
          missing_attributes.map do |attr|
            metadata[attr] = nil
          end

          removed_attributes = metadata.keys - sample_attributes
          removed_attributes.map do |attr|
            metadata.delete(attr)
          end
          # lsdnsdn
          # TODO: Make it a background job
          # For now permission is not necessary and all samples will be updated
          disable_authorization_checks do
            Sample.find(sample.id).update(json_metadata: metadata.to_json)
          end
        end
      end
    end
  end
end
