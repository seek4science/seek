# frozen_string_literal: true

module Seek
  module Samples

    class SampleMetadataUpdateException < StandardError; end

    # Class to handle the updating of sample metadata after updating Sample type
    class SampleMetadataUpdater
      def initialize(sample_type, user, attribute_changes)
        @sample_type = sample_type
        @user = user
        @attribute_change_maps = attribute_changes
      end

      def update_metadata
        return if @attribute_change_maps.blank? || @sample_type.blank? || @user.nil? || @sample_type.samples.blank?

        begin
          User.with_current_user(@user) do
            @sample_type.with_lock do
              @sample_type.samples.in_batches(of: 1000).each do |batch|
                batch.each do |sample|
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
      ensure
        Rails.cache.delete("sample_type_lock_#{@sample_type.id}")
      end

      def raise_sample_metadata_update_exception
        raise SampleMetadataUpdateException.new('An unexpected error occurred while updating the sample metadata')
      end
    end
  end
end