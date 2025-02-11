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
        @annotations ||= query_annotations
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

      # get more details about an annotation from the given property uri
      def annotation_details(property)
        result = Seek::FairDataStation::AnnotationDetails.new(property_id: property)

        query = RDF::Query.new do
          pattern [RDF::Resource.new(property), RDF::RDFS.label, :label]
          pattern [RDF::Resource.new(property), RDF::Vocab::SCHEMA.description, :description], optional: true
          pattern [RDF::URI.new(property), RDF::Vocab::SCHEMA.valuePattern, :pattern], optional: true
          pattern [RDF::URI.new(property), RDF::Vocab::SCHEMA.valueRequired, :required], optional: true
        end
        solution = query.execute(graph).first
        if solution && solution[:label].present?
          result.label = solution[:label].value
          result.description = solution[:description]&.value || ''
          result.pattern = solution[:pattern]&.value || '.*'
          result.required = solution[:required]&.true? || false
        else
          uri = URI.parse(property)
          label = uri.fragment || uri.path.split('/').last
          result.label = label.underscore.humanize(capitalize: false)
          result.description = ''
          result.pattern = '.*'
          result.required = false
        end
        result
      end

      def additional_metadata_annotation_details
        additional_metadata_annotations.collect do |annotation|
          annotation_details(annotation[0])
        end
      end

      def to_extended_metadata_type_json
        json = {}
        json['title'] = "FDS #{type_name.underscore.humanize} #{UUID.generate}"
        json['supported_type'] = type_name
        json['enabled'] = true
        seek_attributes = additional_metadata_annotation_details.collect(&:to_extended_metadata_attribute_json)
        json['attributes'] = seek_attributes
        json
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

      def external_id
        identifier
      end

      def seek_attributes
        { title: title, description: description, external_identifier: external_id }
      end

      def populate_extended_metadata(seek_resource)
        extended_metadata_type = seek_resource.extended_metadata.extended_metadata_type
        data = {}
        additional_metadata_annotations.each do |annotation|
          property_id = annotation[0]
          value = annotation[1]
          data = populate_seek_extended_metadata_for_property(extended_metadata_type, data, property_id, value)
        end
        seek_resource.extended_metadata.data = data
      end

      private

      def populate_seek_extended_metadata_for_property(extended_metadata_type, data, property_id, value)
        attribute = extended_metadata_type.extended_metadata_attributes.where(pid: property_id).first
        if attribute
          data[attribute.accessor_name] = value
        else
          linked_attributes = extended_metadata_type.attributes_with_linked_extended_metadata_type
          linked_attributes.each do |linked_attribute|
            result = populate_seek_extended_metadata_for_property(linked_attribute.linked_extended_metadata_type, {},
                                                                  property_id, value)
            next if result.empty?

            data[linked_attribute.accessor_name] ||= {}
            data[linked_attribute.accessor_name].merge!(result)
            break
          end
        end

        data
      end

      def query_annotations
        sparql = SPARQL::Client.new(graph)
        query = sparql.select.where(
          [resource_uri, :type, :value]
        )

        query.execute.collect do |prop|
          [prop.type.to_s, prop.value.to_s]
        end
      end

      def type_name
        self.class.name.demodulize
      end
    end
  end
end
