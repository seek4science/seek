module Seek
  module Annotatable
    extend ActiveSupport::Concern

    included do
      acts_as_annotatable name_field: :title
    end

    def add_annotations(annotations, attr = 'tag', owner = User.current_user, owned_tags_only = false)
      annotations = annotations.compact_blank if annotations.is_a?(Array)
      annotate_with(annotations, attr, owner, owned_tags_only)
    end

    # returns true or false to indicate the tags have changed
    def annotate_with(annotations, attr = 'tag', owner = User.current_user, user_owned_only = false)
      if annotations.is_a?(String)
        annotations = annotations.split(',').map(&:strip).uniq
      elsif annotations.is_a?(Array)
        annotations = annotations.map(&:strip).uniq
      else
        annotations = []
      end
      potential_values = Array(annotations).uniq(&:downcase).compact

      existing = send("#{attr}_annotations")

      params = {}
      param_index = 0

      any_deletes = false
      duplicates = []
      existing.each do |ann|
        if user_owned_only && ann.source != owner
          params[(param_index += 1).to_s] = { id: ann.id }
        elsif ann.persisted?
          index = potential_values.index { |v| v.casecmp(ann.value_content) == 0 }
          if index
            duplicates << index
            params[(param_index += 1).to_s] = { id: ann.id }
          else
            any_deletes = true
            params[(param_index += 1).to_s] = { id: ann.id, _destroy: true }
          end
        end
      end

      potential_values.delete_if.with_index { |_, i| duplicates.include?(i) }

      potential_values.each do |value|
        # Annotation model can take either a String or an AR object as the value
        text_value = TextValue.where('lower(text) = ?', value.downcase).first || value
        params[(param_index += 1).to_s] = { source_type: owner.class.name, source_id: owner.id,
                                            attribute_name: attr, value: text_value }
      end

      send("#{attr}_annotations").reset # Clear any previously assigned, but unsaved annotations
      send("#{attr}_annotations_attributes=", params)

      potential_values.any? || any_deletes
    end

    def annotations_as_text_array
      annotations.include_values.map(&:value_content)
    end
  end
end
