module Seek
  module Samples
    # Constraints for Sample Attributes at creation time
    class SampleTypeCreationConstraints < SampleTypeEditingConstraints

      def allow_title_change?
        !(attr.is_a?(SampleAttribute) && inherited?(attr))
      end
      def allow_required?(attr)
        !(attr.is_a?(SampleAttribute) && inherited?(attr))
      end

      def allow_attribute_removal?(attr)
        !(attr.is_a?(SampleAttribute) && inherited?(attr))
      end

      # whether the type for the attribute can be changed
      def allow_type_change?(attr)
        !(attr.is_a?(SampleAttribute) && inherited?(attr))
      end

      def allow_isa_tag_change?(attr)
        !(attr.is_a?(SampleAttribute) && inherited?(attr))
      end

      # Unit may be changed as long as the attribute does not have values for any samples
      def allow_unit_change?(attr)
        !(attr.is_a?(SampleAttribute) && inherited?(attr))
      end

    end
  end
end
