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
                        inputs: :input,
                        outputs: :output

        def contributors
          [contributor]
        end

        def image
          return unless resource.diagram_exists?
          diagram_workflow_url(resource, version: resource.version, host: Seek::Config.site_base_host)
        end

        def schema_type
          'ComputationalWorkflow'
        end

        def programming_language
          resource.workflow_class&.title
        end

        def inputs
          formal_parameters(resource.inputs)
        end

        def outputs
          formal_parameters(resource.outputs)
        end

        private

        def formal_parameters(properties)
          properties.collect do |property|
            {
              "@type": 'FormalParameter',
              name: property.id
            }
          end
        end
      end
    end
  end
end
