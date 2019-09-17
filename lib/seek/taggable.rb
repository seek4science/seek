module Seek
  module Taggable
    extend ActiveSupport::Concern

    included do
      include Seek::Annotatable
      has_annotation_type :tag
      has_many :tags_as_text, through: :tag_annotations, source: :value, source_type: 'TextValue'
    end

    class_methods do
      def is_taggable?
        Seek::Config.tagging_enabled
      end
    end

    def is_taggable?
      self.class.is_taggable?
    end

    def searchable_tags
      annotations_as_text_array
    end

    def tags_as_text_array
      annotations.include_values.with_attribute_name('tag').map(&:value_content)
    end
  end
end
