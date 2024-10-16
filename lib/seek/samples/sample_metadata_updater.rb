# frozen_string_literal: true

module Seek
  module Samples

    class SampleMetadataUpdateException < StandardError; end

    # Class to handle the updating of sample metadata after updating Sample type
    class SampleMetadataUpdater
      def initialize(sample_type, attribute_changes, user)
        @sample_type = sample_type
        @attribute_change_maps = attribute_changes
        @user = user
      end

      def update_metadata
        return if @attribute_change_maps.blank? || @sample_type.samples.blank? || @sample_type.nil? || @user.nil?

        User.with_current_user(@user) do
          @sample_type.samples.each do |sample|
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
end