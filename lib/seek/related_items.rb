module Seek
  module RelatedItems
    extend ActiveSupport::Concern

    RELATABLE_TYPES = ['Person', 'Project', 'Institution', 'Investigation', 'Study', 'Assay', 'DataFile', 'Document',
                       'Model', 'Sop', 'Publication', 'Presentation', 'Event', 'Organism', 'Strain', 'Sample',
                       'Workflow', 'Node'].freeze

    class_methods do
      def related_type_methods
        @related_type_methods ||= {}.tap do |hash|
          RELATABLE_TYPES.each do |type|
            method_name = type.underscore.pluralize

            method = if method_defined?("related_#{method_name}")
                       "related_#{method_name}"
                     elsif method_defined?("related_#{method_name.singularize}")
                       "related_#{method_name.singularize}"
                     elsif method_defined?(method_name)
                       method_name
                     elsif type != 'Person' && method_defined?(method_name.singularize) # check is to avoid Person.person
                       method_name.singularize
                     end
            hash[type] = method.to_sym if method
          end
        end
      end
    end

    def get_related(type)
      method = self.class.related_type_methods[type]
      if method
        items = send(method)
        items = [] if items.nil?
        items = [items] if items.is_a?(ApplicationRecord)
        items
      else
        []
      end
    end
  end
end