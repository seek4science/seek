module Seek
  module Samples
    module AttributeTypeHandlers
      class SeekSampleAttributeTypeHandler < BaseAttributeHandler
        class MissingLinkedSampleTypeException < AttributeHandlerException; end

        def test_value(value)
          sample = Sample.find_by_id(value)
          fail 'Unable to find Sample in database' unless sample
          fail 'Sample type does not match' unless sample.sample_type==linked_sample_type
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