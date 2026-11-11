module Seek
  module RoCrate
    # Builds an RO-Crate for an Investigation, shaped after the ISA RO-Crate profile with the ARC
    # directory layout: the Investigation is the root dataset; studies and assays become subdirectory
    # datasets in later steps of the build.
    class ISACrateBuilder
      RO_CRATE_VERSION = '1.2'.freeze
      RO_CRATE_CONTEXT = "https://w3id.org/ro/crate/#{RO_CRATE_VERSION}/context".freeze
      JERM = 'https://jermontology.org/ontology/JERMOntology#'.freeze
      # Investigations, studies and assays carry no license in SEEK; only the assets linked to them do,
      # so the root dataset gets a generic statement rather than a license it cannot vouch for.
      DEFAULT_LICENSE = 'No single license applies to this crate as a whole. ' \
                        'Each included item is subject to its own license.'.freeze
      # Only the bioschemas terms the graph actually uses; a term is added when the builder emits it.
      BIOSCHEMAS_TERMS = {
        'Sample' => 'https://bioschemas.org/Sample',
        'LabProtocol' => 'https://bioschemas.org/LabProtocol',
        'LabProcess' => 'https://bioschemas.org/LabProcess',
        'executesLabProtocol' => 'https://bioschemas.org/properties/executesLabProtocol'
      }.freeze

      attr_reader :investigation, :user

      def initialize(investigation, user = User.current_user)
        @investigation = investigation
        @user = user
      end

      def crate
        @crate ||= build
      end

      def metadata_json
        JSON.parse(crate.metadata.generate)
      end

      private

      def build
        crate = ::ROCrate::Crate.new(version: RO_CRATE_VERSION)
        crate.metadata.context = [RO_CRATE_CONTEXT, BIOSCHEMAS_TERMS]
        set(crate, root_properties)
        keep_root_parts(crate, [])
        crate
      end

      def root_properties
        isa_properties('Investigation', investigation).merge(
          'description' => investigation.description.presence || investigation.title,
          'license' => DEFAULT_LICENSE,
          'datePublished' => Time.now.utc.iso8601
        )
      end

      def isa_properties(type_name, resource)
        { 'additionalType' => isa_type(type_name),
          'identifier' => resource.rdf_seek_id,
          'url' => resource.rdf_seek_id,
          'name' => resource.title,
          'description' => resource.description }
      end

      # additionalType is a list: the IRI of the JERM ontology term, plus the bare name ("Investigation",
      # "Study" or "Assay"). ARC tools only recognise a Dataset as a study or an assay by that exact
      # string; with the JERM IRI alone they silently skip the entity.
      def isa_type(name)
        ["#{JERM}#{name}", name]
      end

      # Assigns only present values, so the crate carries no null or empty properties.
      def set(entity, properties)
        properties.each { |k, v| entity[k] = v unless v.nil? || (v.respond_to?(:empty?) && v.empty?) }
        entity
      end

      # The gem rebuilds the root hasPart from every data entity on write; the root should only list
      # the study and assay directories.
      def keep_root_parts(crate, parts)
        crate.define_singleton_method(:properties) do
          ::ROCrate::Entity.instance_method(:properties).bind(self).call.merge('hasPart' => parts)
        end
      end
    end
  end
end
