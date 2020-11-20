# Imported from the my_annotations plugin developed as part of BioCatalogue and no longer maintained. Originally found at https://github.com/myGrid/annotations

# ActsAsAnnotationSource
module Annotations
  module Acts #:nodoc:
    module AnnotationSource #:nodoc:
      def self.included(base)
        base.send :extend, ClassMethods
      end

      module ClassMethods
        def acts_as_annotation_source
          has_many :annotations_by,
                   -> { order('updated_at ASC') },
                   class_name: 'Annotation',
                   as: :source,
                   inverse_of: :source

          __send__ :extend, SingletonMethods
          __send__ :include, InstanceMethods
        end
      end

      # Class methods added to the model that has been made acts_as_annotation_source (the mixin target class).
      module SingletonMethods
        # Helper finder to get all annotations for an object of the mixin source type with the ID provided.
        # This is the same as +#annotations+ on the object, with the added benefit that the object doesnt have to be loaded.
        # E.g: +User.find_annotations_by(10)+ will give all annotations by User with ID 34.
        def annotations_by(id, include_values = false)
          obj_type = self.class.base_class.name

          options = {
            conditions: { source_type: obj_type,
                          source_id: id },
            order: 'updated_at DESC'
          }

          options[:include] = [:value] if include_values

          Annotation.find(:all, options)
        end

        # Helper finder to get all annotations for all objects of the mixin source type, for the annotatable object provided.
        # E.g: +User.find_annotations_for('Book', 28)+ will give all annotations made by all Users for Book with ID 28.
        def annotations_for(annotatable_type, annotatable_id, include_values = false)
          obj_type = self.class.base_class.name

          options = {
            conditions: { source_type: obj_type,
                          annotatable_type: annotatable_type,
                          annotatable_id: annotatable_id },
            order: 'updated_at DESC'
          }

          options[:include] = [:value] if include_values

          Annotation.find(:all, options)
        end
      end

      # This module contains instance methods
      module InstanceMethods
        # Helper method to get latest annotations
        def latest_annotations(limit = nil, include_values = false)
          options = {
            conditions: { source_type: self.class.name,
                          source_id: id },
            order: 'updated_at DESC',
            limit: limit
          }

          options[:include] = [:value] if include_values

          Annotation.find(:all, options)
        end

        def annotation_source_name
          %w[preferred_name display_name title name].each do |w|
            return self.send(w) if respond_to?(w)
          end
          "#{self.class.name}_#{id}"
        end

        # When used with the default style (:simple), returns a Hash of the +annotations_by+ values
        # grouped by attribute name.
        #
        # Example output:
        # {
        #   "Summary" => "Something interesting happens",
        #   "length" => 345,
        #   "Title" => "Harry Potter and the Exploding Men's Locker Room",
        #   "Tag" => [ "amusing rhetoric", "wizadry" ],
        #   "rating" => "4/5"
        # }
        def annotations_by_hash(_style = :simple)
          h = {}

          unless annotations_by.blank?
            annotations_by.each do |a|
              if h.key?(a.attribute_name)
                case h[a.attribute_name]
                when Array
                  h[a.attribute_name] << a.value_content
                else
                  h[a.attribute_name] = [h[a.attribute_name], a.value_content]
                end
              else
                h[a.attribute_name] = a.value_content
              end
            end
          end

          h
        end
      end
    end
  end
end
