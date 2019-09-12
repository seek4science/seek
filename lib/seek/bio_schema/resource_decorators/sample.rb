module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Sample
      class Sample < BaseDecorator

        def url
          identifier
        end

        def properties
          sample_type.sample_attributes.collect do |attr|
            describe_attribute(attr)
          end
        end

        private

        def describe_attribute(attribute)
          data = {
              "@type"=>"PropertyValue",
              "name"=>attribute.title,
              "value"=>get_attribute(attribute)
          }

          data
        end
      end
    end
  end
end
