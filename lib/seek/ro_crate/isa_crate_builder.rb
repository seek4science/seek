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

      include People
      include Files
      include Samples
      include Processes
      include ExtendedMetadata

      attr_reader :investigation, :user

      # The crate holds what the given user can view; with no user it is the public view, the same
      # for everyone.
      def initialize(investigation, user = nil)
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
        set(crate, root_properties(crate))
        top_level = viewable(investigation.studies).flat_map { |study| add_study(crate, study) }
        keep_root_parts(crate, top_level.map(&:reference))
        crate
      end

      # Returns the study entity followed by its assay entities; all of them sit at the crate root.
      def add_study(crate, study)
        entity = isa_dataset(crate, "studies/#{slug(study)}/", 'Study', study)
        assay_trees = viewable(study.assays.where(assay_stream_id: nil)).map { |assay| add_assay(crate, assay) }
        entity['hasPart'] = assay_trees.map { |tree| tree.first.reference }
        [entity, *assay_trees.flatten]
      end

      # Returns the assay entity followed by the entities of the assays in its stream, if it is one.
      def add_assay(crate, assay)
        entity = isa_dataset(crate, "assays/#{slug(assay)}/", 'Assay', assay)
        set(entity, 'measurementMethod' => assay.assay_type_uri,
                    'measurementTechnique' => assay.technology_type_uri)
        children = viewable(assay.child_assays).flat_map { |child| add_assay(crate, child) }
        files = file_entities(crate, entity.id, assay)
        set(entity, 'hasPart' => (children + files).map(&:reference),
                    'about' => [process_reference(crate, assay, files)].compact)
        [entity, *children]
      end

      def isa_dataset(crate, id, type_name, resource)
        entity = ::ROCrate::DataEntity.new(crate)
        entity.id = id
        entity.type = 'Dataset'
        set(entity, isa_properties(type_name, resource))
        set(entity, linked_properties(crate, type_name, resource))
        crate.add_data_entity(entity)
        entity
      end

      def root_properties(crate)
        isa_properties('Investigation', investigation).merge(
          'description' => investigation.description.presence || investigation.title,
          'license' => DEFAULT_LICENSE,
          'datePublished' => Time.now.utc.iso8601
        ).merge(linked_properties(crate, 'Investigation', investigation))
      end

      # The people and extended metadata of an ISA item, as references to their own entities.
      def linked_properties(crate, type_name, resource)
        { 'creator' => creator_references(crate, resource),
          'additionalProperty' => extended_metadata_references(crate, resource, type_name) }
      end

      # identifier is the bare SEEK id on every level and url the SEEK URL. ARC tools use a study's or
      # assay's identifier as a directory name and allow only letters, digits, underscore, dash and
      # space in it, so a URL is rejected there.
      def isa_properties(type_name, resource)
        { 'additionalType' => isa_type(type_name),
          'identifier' => resource.id.to_s,
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

      # Directory name: SEEK id, then the title lowercased with runs of spaces and punctuation collapsed
      # to one hyphen and capped in length, e.g. "42-heat-stress-in-barley". The id keeps names unique.
      def slug(resource)
        "#{resource.id}-#{resource.title.to_s.parameterize.first(40)}".chomp('-')
      end

      def viewable(relation)
        relation.select { |resource| resource.can_view?(user) }
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
