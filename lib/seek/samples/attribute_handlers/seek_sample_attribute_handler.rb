module Seek
  module Samples
    module AttributeHandlers
      class SeekSampleAttributeHandler < SeekResourceAttributeHandler
        class MissingLinkedSampleTypeException < AttributeHandlerException; end

        def type
          Sample
        end

        def test_value(value)
          if attribute.required?
            sample = find_resource(value['id'])
            raise 'Unable to find Sample in database' unless sample
            raise 'Sample type does not match' unless sample.sample_type == linked_sample_type
          end
        end

        def convert(value)
          super(value.is_a?(Array) ? value.compact_blank.first : value)
        end

        private

        def find_resource(value)
          super(value) || linked_sample_type.samples.find_by_title(value)
        end

        def linked_sample_type
          sample_type = attribute.linked_sample_type
          raise MissingLinkedSampleTypeException unless sample_type

          sample_type
        end
      end
    end
  end
end
