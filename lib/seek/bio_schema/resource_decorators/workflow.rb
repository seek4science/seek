module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Workflow
      class Workflow < CreativeWork
        associated_items sd_publisher: :contributors

        schema_mappings sd_publisher: :sdPublisher,
                        version: :version,
                        image: :image,
                        programming_language: :programmingLanguage,
                        inputs: :inputs,
                        outputs: :outputs

        def contributors
          [contributor]
        end

        def image
          return unless resource.diagram_exists?
          diagram_workflow_url(resource, version: resource.version, host: Seek::Config.site_base_host)
        end

        def schema_type
          'Workflow'
        end

        def programming_language
          resource.workflow_class&.title
        end

        def inputs
          property_value_specs(resource.inputs)
        end

        def outputs
          property_value_specs(resource.outputs)
        end

        private

        def property_value_specs(properties)
          properties.collect do |property|
            {
              "@type": 'PropertyValueSpecification',
              name: property.id
            }
          end
        end
      end
    end
  end
end
