# ActsAsAnnotatable
module Seek
  module AnnotatableExtensions #:nodoc:
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def has_annotation_type(type, method_name: nil)
        method_name ||= type.to_s.pluralize
        has_many "#{type}_annotations".to_sym, -> { where(attribute_id: AnnotationAttribute.find_by_name(type).id) },
                 class_name: 'Annotation',
                 as: :annotatable,
                 dependent: :destroy,
                 inverse_of: :annotatable

        accepts_nested_attributes_for "#{type}_annotations".to_sym, allow_destroy: true

        define_method method_name do
          send("#{type}_annotations").reject(&:marked_for_destruction?).map(&:value_content)
        end

        define_method "#{method_name}=" do |tags|
          add_annotations(tags, type)
        end
      end
    end
  end
end
