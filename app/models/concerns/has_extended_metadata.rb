module HasExtendedMetadata
  extend ActiveSupport::Concern

  included do
    def extended_metadata_attribute_values_for_search
      extended_metadata ? extended_metadata.data.values.reject(&:blank?).uniq : []
    end
  end

  class_methods do
    def has_extended_metadata
      has_one :extended_metadata, as: :item, dependent: :destroy, autosave: true
      accepts_nested_attributes_for :extended_metadata

      if Seek::Config.solr_enabled
        searchable(auto_index: false) do
          text :extended_metadata_attribute_values do
            extended_metadata_attribute_values_for_search
          end
          text :extended_metadata_type do
            extended_metadata.extended_metadata_type.title if extended_metadata.present?
          end
        end
      end
    end
  end
end

