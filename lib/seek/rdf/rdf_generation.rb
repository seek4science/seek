require 'csv'

module Seek
  module Rdf
    module RdfGeneration
      include RdfRepositoryStorage
      include Rightfield::Rightfield
      include CSVMappingsHandling

      def self.included(base)
        base.after_commit :queue_rdf_generation, on: [:create, :update]
        base.before_destroy :remove_rdf
      end

      def to_rdf
        rdf_graph = to_rdf_graph
        RDF::Writer.for(:ttl).buffer(prefixes: ns_prefixes) do |writer|
          rdf_graph.each_statement do |statement|
            writer << statement
          end
        end
      end

      def to_json_ld
        rdf_graph = to_rdf_graph
        context = JSON.parse %(
        {
          "@context": #{ns_prefixes.to_json}
        }
        )

        compacted = nil
        JSON::LD::API.fromRdf(rdf_graph) do |expanded|
          compacted = JSON::LD::API.compact(expanded, context['@context'])
        end
        JSON.pretty_generate(compacted)
      end

      def to_rdf_graph
        rdf_graph = RDF::Graph.new
        rdf_graph = describe_type(rdf_graph)
        rdf_graph = generate_from_csv_definitions rdf_graph
        rdf_graph = additional_triples rdf_graph
        rdf_graph = extended_metadata_triples rdf_graph
        rdf_graph = sample_metadata_triples(rdf_graph) if self.is_a?(Sample)
        rdf_graph
      end

      def handle_rightfield_contents(object)
        graph = nil
        if object.respond_to?(:contains_extractable_spreadsheet?) && object.contains_extractable_spreadsheet?
          begin
            graph = generate_rightfield_rdf_graph(self)
          rescue Exception => e
            Rails.logger.error "Error generating RightField part of rdf for #{object} - #{e.message}"
          end
        end
        graph || RDF::Graph.new
      end

      def rdf_resource
        url = Seek::Util.routes.polymorphic_url(self)
        RDF::Resource.new(url)
      end

      # extra steps that cannot be easily handled by the csv template
      def additional_triples(rdf_graph)
        if is_a?(Model) && contains_sbml?
          rdf_graph << [rdf_resource, JERMVocab.hasFormat, JERMVocab.SBML_format]
        end

        rdf_graph
      end

      def extended_metadata_triples(rdf_graph)
        return rdf_graph unless supports_extended_metadata? && extended_metadata&.extended_metadata_type
        attributes = extended_metadata.extended_metadata_type.extended_metadata_attributes.select{|at| at.pid.present?}
        resource = rdf_resource
        attributes.each do |attribute|
          rdf_graph << [resource, RDF::URI(attribute.pid), RDF::Literal(extended_metadata.get_attribute_value(attribute))]
        end
        rdf_graph
      end

      def sample_metadata_triples(rdf_graph)

        attributes = sample_type.sample_attributes.select{|at| at.pid.present?}
        resource = rdf_resource
        attributes.each do |attribute|
          rdf_graph << [resource, RDF::URI(attribute.pid), RDF::Literal(get_attribute_value(attribute))]
        end
        rdf_graph
      end

      def describe_type(rdf_graph)
        unless rdf_type_entity_fragment.nil?
          resource = rdf_resource
          rdf_graph << [resource, RDF.type, rdf_type_uri]
        end
        rdf_graph
      end

      # this is what is needed for the SEEK_ID term from JERM. It is essentially the same as the resource, but this method
      # make the mappings clearer
      def rdf_seek_id
        rdf_resource.to_s
      end

      # the URI for the type of this object, for example http://jermontology.org/ontology/JERMOntology#Study for a Study
      def rdf_type_uri
        case rdf_type_entity_fragment
        when Symbol
          JERMVocab[rdf_type_entity_fragment]
        when String
          if rdf_type_entity_fragment =~ URI::ABS_URI
            RDF::URI(rdf_type_entity_fragment)
          else
            JERMVocab[rdf_type_entity_fragment]
          end
        end
      end

      def rdf_type_entity_fragment
        JERMVocab.defined_types[self.class]
      end

      # the hash of namespace prefixes to pass to the RDF::Writer when generating the RDF
      def ns_prefixes
        {
          'jerm' => JERMVocab.to_uri.to_s,
          'dcterms' => RDF::Vocab::DC.to_uri.to_s,
          'owl' => RDF::Vocab::OWL.to_uri.to_s,
          'foaf' => RDF::Vocab::FOAF.to_uri.to_s,
          'sioc' => RDF::Vocab::SIOC.to_uri.to_s,
          'mixs' => 'https://w3id.org/mixs/',
          'uniprot' => 'http://purl.uniprot.org/core/',
          'fairbd' => 'http://fairbydesign.nl/ontology/',
          'xsd' => 'http://www.w3.org/2001/XMLSchema#'
        }
      end

      def queue_rdf_generation(force = false, refresh_dependents = true)
        unless !force && (saved_changes.keys - ['updated_at']).empty?
          RdfGenerationQueue.enqueue(self, refresh_dependents: refresh_dependents)
        end
      end

      def remove_rdf
        remove_rdf_from_repository if rdf_repository_configured?
        delete_rdf_file
        queue_dependents_rdf_generation
      end

      def queue_dependents_rdf_generation
        RdfGenerationQueue.enqueue(dependent_items, priority: 3)
      end

      def dependent_items
        items = []
        # FIXME: this should go into a seperate mixin for active-record
        methods = %i[data_files sops models publications
                     data_file_masters sop_masters model_masters
                     assets
                     assays studies investigations observation_units
                     institutions creators owners owner contributors contributor projects events presentations organisms strains]
        methods.each do |method|
          next unless respond_to?(method)
          deps = Array(send(method))
          # resolve User back to Person
          deps = deps.collect { |dep| dep.is_a?(User) ? [dep, dep.person] : dep }.flatten.compact
          items |= deps
        end

        items |= related_items_from_sparql if rdf_repository_configured?

        items.compact.uniq
      end

      def refresh_rdf
        queue_rdf_generation(true, false)
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  def rdf_supported?
    Seek::Util.rdf_capable_types.include?(self.class)
  end
end