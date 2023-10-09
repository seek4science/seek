module HasCustomMetadata
  extend ActiveSupport::Concern

  included do
    def custom_metadata_attribute_values_for_search
      custom_metadata ? custom_metadata.data.values.reject(&:blank?).uniq : []
    end
  end

  class_methods do
    def has_extended_custom_metadata
      has_one :custom_metadata, as: :item, dependent: :destroy, autosave: true
      accepts_nested_attributes_for :custom_metadata

      if Seek::Config.solr_enabled
        searchable(auto_index: false) do
          text :custom_metadata_attribute_values do
            custom_metadata_attribute_values_for_search
          end
          text :custom_metadata_type do
            custom_metadata.custom_metadata_type.title if custom_metadata.present?
          end
        end
      end
    end
  end
end

