module Seek
  module Samples
    module AttributeTypeHandlers
      class SeekSampleAttributeTypeHandler < BaseAttributeHandler
        class MissingLinkedSampleTypeException < AttributeHandlerException; end

        def test_value(value)
          sample = Sample.find_by_id(convert(value))
          fail 'Unable to find Sample in database' unless sample
          fail 'Sample type does not match' unless sample.sample_type == linked_sample_type
        end

        def convert(value)
          Integer(value)
          value
        rescue ArgumentError
          (sample = linked_sample_type.samples.find_by_title(value)) ? sample.id : value
        end

        private

        def linked_sample_type
          sample_type = additional_options[:linked_sample_type]
          fail MissingLinkedSampleTypeException.new unless sample_type
          sample_type
        end
      end
    end
  end
end
