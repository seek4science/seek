module Seek
  module Taggable
    extend ActiveSupport::Concern

    included do
      extend ClassMethods
      acts_as_annotatable name_field: :title
      has_annotation_type :tag
    end

    def is_taggable?
      self.class.is_taggable?
    end

    # tag_with_params
    def add_annotations(annotations, attr = 'tag', owner = User.current_user, owned_tags_only = false)
      tags = resolve_tags(annotations)
      tag_with(tags, attr, owner, owned_tags_only)
    end

    def resolve_tags(annotations)
      if annotations.is_a?(String)
        annotations.split(',').map(&:strip).uniq
      elsif annotations.is_a?(Array)
        annotations.map(&:strip).uniq
      else
        []
      end
    end

    # returns true or false to indicate the tags have changed
    def tag_with(annotations, attr = 'tag', owner = User.current_user, user_owned_only = false)
      value_to_add = Array(annotations).uniq(&:downcase).compact

      existing = send("#{attr}_annotations")

      params = {}
      param_index = 0

      any_deletes = false
      existing.each do |ann|
        if user_owned_only && ann.source != owner
          params[(param_index += 1).to_s] = { id: ann.id }
        elsif ann.persisted?
          index = value_to_add.index { |v| v.casecmp(ann.value_content) == 0 }
          if index
            value_to_add.delete_at(index)
            params[(param_index += 1).to_s] = { id: ann.id }
          else
            any_deletes = true
            params[(param_index += 1).to_s] = { id: ann.id, _destroy: true }
          end
        end
      end

      value_to_add.each do |value|
        # Annotation model can take either a String or an AR object as the value
        text_value = TextValue.where('lower(text) = ?', value.downcase).first || value
        params[(param_index += 1).to_s] = { source_type: owner.class.name, source_id: owner.id,
                                            attribute_name: attr, value: text_value }
      end

      send("#{attr}_annotations").reset # Clear any previously assigned, but unsaved annotations
      send("#{attr}_annotations_attributes=", params)

      value_to_add.any? || any_deletes
    end

    def searchable_tags
      annotations_as_text_array
    end

    def annotations_as_text_array
      annotations.include_values.map(&:value_content)
    end

    def tags_as_text_array
      annotations.include_values.with_attribute_name('tag').map(&:value_content)
    end

    module ClassMethods
      def is_taggable?
        Seek::Config.tagging_enabled
      end
    end
  end
end
