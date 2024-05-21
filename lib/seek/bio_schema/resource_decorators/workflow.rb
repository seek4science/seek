module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Workflow
      class Workflow < CreativeWork
        WORKFLOW_PROFILE = 'https://bioschemas.org/profiles/ComputationalWorkflow/1.0-RELEASE/'.freeze



        schema_mappings programming_language: :programmingLanguage,
                        inputs: :input,
                        outputs: :output,
                        sd_publisher: :sdPublisher

        def contributors
          [contributor]
        end

        def conformance
          WORKFLOW_PROFILE
        end

        def image
          return unless resource.diagram_exists?

          diagram_workflow_url(resource, version: resource.version, **Seek::Config.site_url_options)
        end

        def schema_type
          %w[SoftwareSourceCode ComputationalWorkflow]
        end

        def programming_language
          resource.workflow_class&.ro_crate_metadata
        end

        def inputs
          formal_parameters(resource.inputs)
        end

        def outputs
          formal_parameters(resource.outputs)
        end

        def license
          Seek::License.find(resource.license)&.url
        end

        def sd_publisher
          DataCatalogMockModel.new.provider
        end

        private

        def formal_parameters(properties)
          properties.map(&:ro_crate_metadata)
        end
      end
    end
  end
end
