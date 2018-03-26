# ActsAsAnnotatable
module Seek
  module AnnotatableExtensions #:nodoc:
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def has_annotations(field, attribute_name: nil)
        attribute_name ||= field.to_s.singularize
        has_many field, -> { with_attribute_name(attribute_name) },
                 class_name: 'Annotation',
                 as: :annotatable,
                 dependent: :destroy,
                 inverse_of: :annotatable,
                 autosave: true
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Seek::AnnotatableExtensions
end
