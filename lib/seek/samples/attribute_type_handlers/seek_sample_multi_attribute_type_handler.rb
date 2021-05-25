module Seek
  module Samples
    module AttributeTypeHandlers
      class SeekSampleMultiAttributeTypeHandler < SeekResourceAttributeTypeHandler
        class MissingLinkedSampleTypeException < AttributeHandlerException; end

        def type
          'Sample'
        end

        def test_value(value)
          if value.kind_of?(Array)
            value.each {|v| test_value_item v}
          else
            test_value_item value
          end
        end

        def convert(value)
          if value.kind_of?(Array)
            value.uniq.map {|v| get_conversion v}
          else
            if value.include? ','
              value.split(',').map(&:strip).uniq.map {|v| get_conversion v}
            else
              get_conversion value
            end
          end
        end

        private

        def get_conversion(value)
          resource = find_resource(value)
          hash = { id: resource ? resource.id : value, type: type }.with_indifferent_access
          hash[:title] = resource.title if resource
          hash
        end

        def test_value_item(value)
          if additional_options[:required]
            sample = find_resource(value['id'])
            fail 'Unable to find Sample in database' unless sample
            fail 'Sample type does not match' unless sample.sample_type == linked_sample_type
          end
        end

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
