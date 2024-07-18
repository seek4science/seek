module Seek
  module FairDataStation
    class Base
      attr_reader :resource_uri, :graph, :children, :core_annotations

      def initialize(resource_uri, graph)
        @resource_uri = resource_uri
        @graph = graph
        @jerm = RDF::Vocabulary.new('http://jermontology.org/ontology/JERMOntology#')
        @schema = RDF::Vocabulary.new('http://schema.org/')
        @fair = RDF::Vocabulary.new('http://fairbydesign.nl/ontology/')
        @children = []
        @core_annotations = [
          @schema.contributor,
          @schema.dataset,
          @schema.description,
          @schema.identifier,
          @schema.name,
          @schema.title,
          @schema.contentUrl,
          RDF.type,
          @jerm.hasPart
        ]
      end

      def identifier
        find_annotation_value(@schema.identifier.to_s)
      end

      def title
        find_annotation_value(@schema.title) || find_annotation_value(@schema.name)
      end

      def description
        find_annotation_value(@schema.description)
      end

      def annotations
        @_cached_annotations ||= query_annotations


      end

      def additional_metadata_annotations
        annotations.reject do |annotation|
          core_annotations.include?(annotation[0])
        end
      end

      def find_annotation_value(property)
        annotations.detect do |ann|
          ann[0] == property
        end&.[](1)
      end

      def pp_annotations
        annotations.sort_by { |a| a[0] }.each do |pair|
          pp "#{pair[0]} -> #{pair[1]}"
        end
      end

      def populate
        fetch_children.collect do |child|
          add_child(child)
        end
      end

      def add_child(child)
        @children << child_class.new(child, graph)
        @children.last.populate
      end

      def datasets
        sparql = SPARQL::Client.new(graph)
        query = sparql.select.where(
          [resource_uri, @schema.dataset, :dataset]
        )
        query.execute.collect do |solution|
          Seek::FairDataStation::DataSet.new(solution.dataset, graph)
        end
      end

      def fetch_children
        sparql = SPARQL::Client.new(graph)
        query = sparql.select.where(
          [resource_uri, @jerm.hasPart, :child]
        )

        query.execute.collect(&:child)
      end

      def seek_attributes
        { title: title, description: description }
      end

      def populate_extended_metadata(seek_resource)
        extended_metadata_type = seek_resource.extended_metadata.extended_metadata_type
        data = {}
        additional_metadata_annotations.each do |annotation|
          property = annotation[0]
          value = annotation[1]
          attribute = extended_metadata_type.extended_metadata_attributes.where(pid: property).first
          data[attribute.title] = value if attribute
        end
        seek_resource.extended_metadata.data = data
      end

      private

      def query_annotations
        sparql = SPARQL::Client.new(graph)
        query = sparql.select.where(
          [resource_uri, :type, :value]
        )

        query.execute.collect do |prop|
          [prop.type.to_s, prop.value.to_s]
        end
      end
    end
  end
end
