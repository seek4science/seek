module Seek
  module RelatedItems
    extend ActiveSupport::Concern

    RELATABLE_TYPES = ['Person', 'Programme', 'Project', 'Institution', 'Investigation', 'Study', 'Assay', 'DataFile',
                       'Document', 'Model', 'Sop', 'Publication', 'Presentation', 'Event', 'Organism', 'Strain',
                       'SampleType', 'Sample', 'Workflow', 'Collection', 'HumanDisease', 'FileTemplate', 'Placeholder',
                       'Template'].freeze

    # special cases of associations to be skipped { self: relatable_type  }
    RELATABLE_TYPES_DENYLIST = {
      Person: 'Person',
      Template: 'Organism'
    }.with_indifferent_access.freeze

    class_methods do
      def related_type_methods
        @related_type_methods ||= {}.tap do |hash|
          RELATABLE_TYPES.each do |type|
            next if RELATABLE_TYPES_DENYLIST[self.name] == type

            method_name = type.underscore.pluralize

            potential_methods = ["related_#{method_name}", "related_#{method_name.singularize}", method_name, method_name.singularize]
            method = potential_methods.detect { |m| method_defined?(m) }

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
