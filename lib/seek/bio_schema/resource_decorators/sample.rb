module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Sample
      class Sample < Thing
        schema_mappings properties: :additionalProperty

        SAMPLE_PROFILE = 'https://bioschemas.org/profiles/Sample/0.2-RELEASE-2018_11_10/'.freeze

        def schema_type
          %w[Sample]
        end

        def conformance
          SAMPLE_PROFILE
        end

        def properties
          sample_type.sample_attributes.collect do |attr|
            describe_attribute(attr)
          end
        end

        private

        def describe_attribute(attribute)
          value = get_attribute_value(attribute) || ''
          data = {
            '@type' => 'PropertyValue',
            'name' => attribute.title,
            'value' => value.to_s
          }
          if attribute.pid
            data['propertyId'] = attribute.pid
          end
          resolved = attribute.resolve(value)
          data['identifier'] = resolved if resolved
          if attribute.unit
            data['unitCode'] = attribute.unit.symbol
            data['unitText'] = attribute.unit.title || attribute.unit.comment
          end
          data
        end
      end
    end
  end
end
