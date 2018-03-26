module Seek
  module Taggable
    extend ActiveSupport::Concern

    included do
      extend ClassMethods
      acts_as_seek_annotatable name_field: :title
      has_annotations :tags
    end

    def is_taggable?
      self.class.is_taggable?
    end

    # tag_with_params
    def tag_annotations(annotations, attr = 'tag', owner = User.current_user, owned_tags_only = false)
      tags = resolve_tags(annotations)
      tag_with(tags, attr, owner, owned_tags_only)
    end

    def resolve_tags(annotations)
      if annotations
        annotations.split(',').map(&:strip).uniq
      else
        []
      end
    end

    # returns true or false to indicate the tags have changed
    def tag_with(tags, attr = 'tag', owner = User.current_user, owned_tags_only = false)
      values_to_add = Array(tags).uniq(&:downcase).compact

      existing = annotations_with_attribute(attr)
      existing = existing.select { |t| t.source == owner } if owned_tags_only

      tags_removed = false
      existing.each do |tag|
        index = values_to_add.index { |v| v.casecmp(tag.value.text) == 0 }
        if index
          values_to_add.delete_at(index)
        else
          tags_removed = true
          tag.mark_for_destruction
        end
      end

      values_to_add.each do |value|
        text_value = TextValue.where('lower(text) = ?', value.downcase).first_or_initialize(text: value)
        annotations.build(source: owner, attribute_name: attr, value: text_value)
      end

      values_to_add.any? || tags_removed
    end

    def searchable_tags
      annotations_as_text_array
    end

    def annotations_as_text_array
      annotations.include_values.collect { |a| a.value.text }
    end

    def tags_as_text_array
      annotations.include_values.with_attribute_name('tag').collect { |a| a.value.text }
    end

    module ClassMethods
      def is_taggable?
        Seek::Config.tagging_enabled
      end
    end
  end
end
