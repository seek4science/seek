module Seek
  module ActsAsCustomMetadata
    extend ActiveSupport::Concern

    class_methods do
      def has_extended_custom_metadata
        has_one :custom_metadata, as: :item, dependent: :destroy
        accepts_nested_attributes_for :custom_metadata
      end
    end
  end
end
