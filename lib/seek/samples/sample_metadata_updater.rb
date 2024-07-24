# frozen_string_literal: true

module Seek
  module Samples

    class SampleMetadataUpdateException < StandardError; end

    # Class to handle the updating of sample metadata after updating Sample type
    class SampleMetadataUpdater
      def initialize(sample_type)
        @sample_type = sample_type
      end

      def update_metadata
        samples = @sample_type.samples
        # Should raise an exception if the user does not have permission to update all the samples in this sample type.
        raise SampleMetadataUpdateException('Invalid permissions! You need editing permission to all samples in this sample type.') unless samples.all?(&:can_edit?)

        sample_attributes = @sample_type.sample_attributes.map(&:title)

        samples.each do |sample|
          metadata = JSON.parse(sample.json_metadata)
          # Skip this sample if the sample attributes are the same as the JSON metadata keys
          next if metadata.keys == sample_attributes

          missing_attributes = sample_attributes - metadata.keys
          missing_attributes.map do |attr|
            metadata[attr] = nil
          end

          removed_attributes = metadata.keys - sample_attributes
          removed_attributes.map do |attr|
            metadata.delete(attr)
          end
          # For now permission are skipped and all samples will be updated
          sample.update_column(:json_metadata, metadata.to_json)
        end
      end
    end
  end
end