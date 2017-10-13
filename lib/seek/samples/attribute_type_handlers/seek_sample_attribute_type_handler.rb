module Seek
  module Samples
    module AttributeTypeHandlers
      class SeekSampleAttributeTypeHandler < SeekResourceAttributeTypeHandler
        class MissingLinkedSampleTypeException < AttributeHandlerException; end

        def type
          'Sample'
        end

        def test_value(value)
          super
          sample = find_resource(value)
          fail 'Unable to find Sample in database' unless sample
          fail 'Sample type does not match' unless sample.sample_type == linked_sample_type
        end

        private

        def find_resource(value)
          super(value) || linked_sample_type.samples.find_by_title(value)
        end

        def linked_sample_type
          sample_type = additional_options[:linked_sample_type]
          fail MissingLinkedSampleTypeException.new unless sample_type
          sample_type
        end
      end
    end
  end
end
