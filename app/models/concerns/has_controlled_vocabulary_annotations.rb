# To support linking a model to an ontology based controlled vocabulary, currently for Topics, Operations, Format types and Data types
module HasControlledVocabularyAnnotations
  extend ActiveSupport::Concern

  included do
    def supports_controlled_vocab_annotations?(property = nil)
      if property.nil?
        self.class.supported_controlled_vocab_properties.present?
      else
        self.class.supported_controlled_vocab_properties.include?(property)
      end
    end

    def controlled_vocab_annotations?
      return false unless supports_controlled_vocab_annotations?

      self.class.supported_controlled_vocab_properties.detect do |prop|
        send("#{prop.to_s.singularize}_annotations").any?
      end.present?
    end
  end

  class_methods do
    attr_reader :supported_controlled_vocab_properties

    def has_controlled_vocab_annotations(*properties)
      include InstanceMethods

      @supported_controlled_vocab_properties = Array(properties) & SampleControlledVocab::SystemVocabs.valid_properties

      @supported_controlled_vocab_properties.each do |property|
        define_controlled_vocab_annotation_associations(property)

        define_controlled_vocab_annotation_methods(property)

        define_controlled_vocab_annotation_index_filters(property)

        define_controlled_vocab_annotation_search_indexing(property)
      end
    end

    private

    def define_controlled_vocab_annotation_search_indexing(property)
      return unless Seek::Config.solr_enabled

      searchable(auto_index: false) do
        text "#{property.to_s.singularize}_annotations".to_sym do
          controlled_vocab_annotation_labels(property)
        end
      end
    end

    def define_controlled_vocab_annotation_associations(property)
      has_annotation_type "#{property.to_s.singularize}_annotations".to_sym
      has_many "#{property.to_s.singularize}_annotation_values".to_sym,
               through: "#{property.to_s.singularize}_annotations_annotations".to_sym, source: :value,
               source_type: 'SampleControlledVocabTerm'
    end

    def define_controlled_vocab_annotation_methods(property)
      # the topics  vals can be an array or comma seperated list of either labels or IRI's
      define_method "#{property.to_s.singularize}_annotations=" do |vals|
        associate_controlled_vocab_annotation_values vals, property
      end

      define_method "#{property.to_s.singularize}_annotation_labels" do
        controlled_vocab_annotation_labels(property)
      end
    end

    def define_controlled_vocab_annotation_index_filters(property)
      # INDEX filters. Unfortunately, these won't currently consider the hierarchy

      # key needs to match attribute defined in en.yml
      has_filter "attributes.#{property.to_s.singularize}_annotation_values": Seek::Filtering::Filter.new(
        value_field: 'sample_controlled_vocab_terms.label',
        joins: ["#{property.to_s.singularize}_annotation_values".to_sym]
      )
    end
  end

  module InstanceMethods
    def annotation_controlled_vocab(property)
      SampleControlledVocab::SystemVocabs.vocab_for_property(property)
    end

    private

    # the topics can be an array or comma seperated list of either labels or IRI's
    def associate_controlled_vocab_annotation_values(vals, property)
      vocab = annotation_controlled_vocab(property)
      values = Array(vals.split(',').flatten).map do |value|
        value = value.strip
        next if value.blank?
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

    def controlled_vocab_annotation_labels(property)
      controlled_vocab_annotation_values(property).pluck(:label)
    end

    def controlled_vocab_annotation_values(property)
      send("#{property.to_s.singularize}_annotation_values")
    end
  end
end
