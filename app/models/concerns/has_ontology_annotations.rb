# To support linking a model to the EDAM ontology, and for each branch of Topics, Operations, Formats and Data
module HasOntologyAnnotations
  extend ActiveSupport::Concern

  included do
    def supports_ontology_annotations?(property = nil)
      if property.nil?
        self.class.supported_ontology_properties.present?
      else
        self.class.supported_ontology_properties.include?(property)
      end
    end

    def ontology_annotations?
      return false unless supports_ontology_annotations?

      self.class.supported_ontology_properties.detect do |prop|
        send("#{prop.to_s.singularize}_annotations").any?
      end.present?
    end
  end

  class_methods do
    attr_reader :supported_ontology_properties

    def has_edam_annotations(*properties)
      include InstanceMethods

      @supported_ontology_properties = Array(properties) & %i[topics operations data formats]

      @supported_ontology_properties.each do |property|
        define_ontology_annotation_associations(property)

        define_ontology_annotation_methods(property)

        define_ontology_annotation_index_filters(property)

        define_ontology_annotation_search_indexing(property)
      end
    end

    private

    def define_ontology_annotation_search_indexing(property)
      return unless Seek::Config.solr_enabled

      searchable(auto_index: false) do
        text "#{property.to_s.singularize}_annotations".to_sym do
          ontology_annotation_labels(property)
        end
      end
    end

    def define_ontology_annotation_associations(property)
      has_annotation_type "#{property.to_s.singularize}_annotations".to_sym
      has_many "#{property.to_s.singularize}_annotation_values".to_sym,
               through: "#{property.to_s.singularize}_annotations_annotations".to_sym, source: :value,
               source_type: 'SampleControlledVocabTerm'
    end

    def define_ontology_annotation_methods(property)
      # the topics  vals can be an array or comma seperated list of either labels or IRI's
      define_method "#{property.to_s.singularize}_annotations=" do |vals|
        associate_ontology_annotation_values vals, property
      end

      define_method "#{property.to_s.singularize}_annotation_labels" do
        ontology_annotation_labels(property)
      end
    end

    def define_ontology_annotation_index_filters(property)
      # INDEX filters. Unfortunately, these won't currently consider the hierarchy
      has_filter "#{property.to_s.singularize}_annotation": Seek::Filtering::Filter.new(
        value_field: 'sample_controlled_vocab_terms.label',
        joins: ["#{property.to_s.singularize}_annotation_values".to_sym]
      )
    end
  end

  module InstanceMethods
    private

    def ontology_annotation_vocab(property)
      SampleControlledVocab::SystemVocabs.send("#{property}_controlled_vocab")
    end

    # the topics can be an array or comma seperated list of either labels or IRI's
    def associate_ontology_annotation_values(vals, property)
      vocab = ontology_annotation_vocab(property)
      values = Array(vals.split(',').flatten).map do |value|
        value = value.strip
        vocab.sample_controlled_vocab_terms.find_by_label(value) ||
          vocab.sample_controlled_vocab_terms.find_by_iri(value)
      end.compact.uniq

      annotations = send("#{property.to_s.singularize}_annotations_annotations")

      annotations.delete_all
      values.map do |annotation|
        annotations.build(source: User.current_user, value: annotation)
      end

      values
    end

    def ontology_annotation_labels(property)
      ontology_annotation_values(property).pluck(:label)
    end

    def ontology_annotation_values(property)
      send("#{property.to_s.singularize}_annotation_values")
    end
  end
end
