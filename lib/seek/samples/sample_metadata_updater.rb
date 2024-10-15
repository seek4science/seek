# frozen_string_literal: true

module Seek
  module Samples

    class SampleMetadataUpdateException < StandardError; end

    # Class to handle the updating of sample metadata after updating Sample type
    class SampleMetadataUpdater
      def initialize(sample_type, attribute_changes)
        @sample_type = sample_type
        @attribute_change_maps = attribute_changes
      end

      def update_metadata
        samples = @sample_type.samples
        # Should raise an exception if the user does not have permission to update all the samples in this sample type.
        raise SampleMetadataUpdateException('Invalid permissions! You need editing permission to all samples in this sample type.') unless samples.all?(&:can_edit?)

        samples.each do |sample|
          metadata = JSON.parse(sample.json_metadata)
          # Update the metadata keys with the new attribute titles
          @attribute_change_maps.each do |change|
            metadata[change[:new_title]] = metadata.delete(change[:old_title])
          end
          sample.update_column(:json_metadata, metadata.to_json)
        end
      end
    end
  end
end