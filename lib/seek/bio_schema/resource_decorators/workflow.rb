module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Workflow
      class Workflow < CreativeWork
        WORKFLOW_PROFILE = 'https://bioschemas.org/profiles/ComputationalWorkflow/1.0-RELEASE/'.freeze
        WORKFLOW_TYPE = 'https://bioschemas.org/terms/ComputationalWorkflow'.freeze
        FORMALPARAMETER_PROFILE = 'https://bioschemas.org/profiles/FormalParameter/1.0-RELEASE/'.freeze
        FORMALPARAMETER_TYPE = 'https://bioschemas.org/terms/FormalParameter'.freeze
        INPUT_PROPERTY = 'https://bioschemas.org/terms/input'.freeze
        OUTPUT_PROPERTY = 'https://bioschemas.org/terms/output'.freeze
        # the DefinedTermSet for the terms of each controlled vocabulary annotation property
        TERM_SETS = {
          topics: 'http://edamontology.org',
          operations: 'http://edamontology.org',
          disciplines: 'https://openalex.org/fields'
        }.freeze

        associated_items docs_and_sops: %i[documents sops]

        schema_mappings programming_language: :programmingLanguage,
                        inputs: :input,
                        outputs: :output,
                        sd_publisher: :sdPublisher,
                        maturity: :creativeWorkStatus,
                        docs_and_sops: :documentation,
                        subjects: :about,
                        operations: :featureList

        def context
          super.merge(
            input: INPUT_PROPERTY,
            output: OUTPUT_PROPERTY,
            ComputationalWorkflow: WORKFLOW_TYPE,
            FormalParameter: FORMALPARAMETER_TYPE
          )
        end

        def maturity
          return nil unless resource.maturity_level.present?

          I18n.t("maturity_level.#{resource.maturity_level}")
        end

        def conformance
          WORKFLOW_PROFILE
        end

        # the diagram, which is generated when first requested if it hasn't been already
        def image
          return unless resource.diagram_exists? || resource.can_render_diagram?

          diagram_workflow_url(parent_resource, version: resource.version, **Seek::Config.site_url_options)
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

        # the EDAM topics and scientific disciplines the workflow is about
        def subjects
          terms = Array(defined_terms(:topics)) + Array(defined_terms(:disciplines))
          terms.presence
        end

        # the EDAM operations the workflow performs
        def operations
          defined_terms(:operations)
        end

        private

        # the controlled vocabulary annotations for the property, as DefinedTerms identified by their IRI
        def defined_terms(property)
          accessor = "#{property.to_s.singularize}_annotation_values"
          return unless parent_resource.respond_to?(accessor)

          terms = parent_resource.send(accessor).to_a
          return if terms.empty?

          term_set = TERM_SETS[property]
          terms.collect do |term|
            definition = {
              '@type' => 'DefinedTerm',
              '@id' => term.iri.presence || ROCrate::ContextualEntity.format_local_id(term.label),
              'name' => term.label
            }
            definition['inDefinedTermSet'] = { '@id' => term_set } if term_set && term.iri&.start_with?(term_set)
            definition
          end
        end

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
              "dct:conformsTo": { '@id' => FORMALPARAMETER_PROFILE }
            }
          end
        end
      end
    end
  end
end
