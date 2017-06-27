module Seek
  module Taggable
    extend ActiveSupport::Concern

    included do
      extend ClassMethods
      acts_as_annotatable name_field: :title
    end

    def is_taggable?
      self.class.is_taggable?
    end

    # tag_as_user_with_params
    def tag_annotations_as_user(annotations, attr = 'tag', owner = User.current_user)
      tags = resolve_tags(annotations)
      tag_as_user_with(tags, attr, owner)
    end

    # tag_with_params
    def tag_annotations(annotations, attr = 'tag', owner = User.current_user)
      tags = resolve_tags(annotations)
      tag_with(tags, attr, owner)
    end

    def resolve_tags(annotations)
      if annotations
        annotations.split(',').map(&:strip).uniq
      else
        []
      end
    end

    def resolve_tags_from_params(_annotations)
      tags = []

      selected_key = "#{attr}_autocompleter_selected_ids".to_sym
      unrecognized_key = "#{attr}_autocompleter_unrecognized_items".to_sym

      unless params[selected_key].nil?
        Array(params[selected_key]).each do |selected_id|
          tag = TextValue.find(selected_id)
          tags << tag.text
        end
      end

      unless params[unrecognized_key].nil?
        Array(params[unrecognized_key]).each do |item|
          tags << item
        end
      end

      tags << params[:annotation][:value] if params[:annotation] && params[:annotation][:value]

      tags
    end

    def tag_as_user_with(tags, attr = 'tag', owner = User.current_user)
      tag_with tags, attr, owner, true
    end

    # returns true or false to indicate the tags have changed
    def tag_with(tags, attr = 'tag', owner = User.current_user, owned_tags_only = false)
      tags = Array(tags)
      # FIXME: yuck! - this is required so that self has an id and can be assigned to an Annotation.annotatable
      return if new_record? && !save

      current = annotations_with_attribute(attr)
      original = current
      current = current.select { |c| c.source == owner } if owned_tags_only
      for_removal = []
      current.each do |cur|
        for_removal << cur unless tags.include?(cur.value.text)
      end

      tags.each do |tag|
        exists = TextValue.where('lower(text) = ?', tag.downcase)
        # text_value exists for this attr
        if !exists.empty?

          # isn't already used as an annotation for this entity
          if owned_tags_only
            matching = Annotation.for_annotatable(self.class.name, id).with_attribute_name(attr).by_source(owner.class.name, owner.id).select { |a| a.value.text.casecmp(tag.downcase).zero? }
          else
            matching = Annotation.for_annotatable(self.class.name, id).with_attribute_name(attr).select { |a| a.value.text.casecmp(tag.downcase).zero? }
          end

          if matching.empty?
            annotation = Annotation.new(source: owner,
                                        annotatable: self,
                                        attribute_name: attr,
                                        value: exists.first)
            annotation.save!
          end
        else
          annotation = Annotation.new(source: owner,
                                      annotatable: self,
                                      attribute_name: attr,
                                      value: tag)
          annotation.save!
        end
      end
      for_removal.each(&:destroy)
      # return if the annotations have changed. just use the text to avoid issues with ID's changing
      original = original.collect { |a| a.value.text }.sort
      new = annotations_with_attribute(attr).collect { |a| a.value.text }.sort
      original != new
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
