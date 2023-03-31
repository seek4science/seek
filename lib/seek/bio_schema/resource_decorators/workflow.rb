module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Workflow
      class Workflow < CreativeWork
        WORKFLOW_PROFILE = 'https://bioschemas.org/profiles/ComputationalWorkflow/1.0-RELEASE/'.freeze

        FORMALPARAMETER_PROFILE = 'https://bioschemas.org/profiles/FormalParameter/1.0-RELEASE/'.freeze

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
          formal_parameters(resource.inputs, 'inputs')
        end

        def outputs
          formal_parameters(resource.outputs, 'outputs')
        end

        def license
          Seek::License.find(resource.license)&.url
        end

        def sd_publisher
          DataCatalogMockModel.new.provider
        end

        private

        def formal_parameters(properties, group_name)
          wf_name = if title
                      title.downcase.gsub(/[^0-9a-z]/i, '_')
                    else
                      'dummy'
                    end
          properties.collect do |property|
            {
              "@type": 'FormalParameter',
              "@id": ROCrate::ContextualEntity.format_local_id("#{wf_name}-#{group_name}-#{property.id}"),
              name: property.name || property.id,
              "dct:conformsTo": FORMALPARAMETER_PROFILE
            }
          end
        end
      end
    end
  end
end
