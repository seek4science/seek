# To support linking a model to the EDAM ontology, and for each branch of Topics, Operations, Formats and Data
module HasEdamAnnotations
  extend ActiveSupport::Concern

  included do
    def supports_edam_annotations?(property = nil)
      if property.nil?
        self.class.supported_edam_properties.present?
      else
        self.class.supported_edam_properties.include?(property)
      end
    end

    def edam_annotations?
      return false unless supports_edam_annotations?

      self.class.supported_edam_properties.detect do |prop|
        send("edam_#{prop}").any?
      end.present?
    end
  end

  class_methods do
    attr_reader :supported_edam_properties

    def has_edam_annotations(*properties)
      include InstanceMethods

      @supported_edam_properties = Array(properties) & %i[topics operations data formats]

      @supported_edam_properties.each do |property|
        define_edam_associations(property)

        define_edam_methods(property)

        define_edam_index_filters(property)

        define_edam_search_indexing(property)
      end
    end

    private

    def define_edam_search_indexing(property)
      return unless Seek::Config.solr_enabled

      searchable(auto_index: false) do
        text "edam_#{property}".to_sym do
          edam_labels(property)
        end
      end
    end

    def define_edam_associations(property)
      has_annotation_type "edam_#{property}".to_sym
      has_many "edam_#{property.to_s.singularize}_values".to_sym,
               through: "edam_#{property}_annotations".to_sym, source: :value,
               source_type: 'SampleControlledVocabTerm'
    end

    def define_edam_methods(property)
      # the topics  vals can be an array or comma seperated list of either labels or IRI's
      define_method "edam_#{property}=" do |vals|
        associate_edam_values vals, property
      end

      define_method "edam_#{property.to_s.singularize}_labels" do
        edam_labels(property)
      end
    end

    def define_edam_index_filters(property)
      # INDEX filters. Unfortunately, these won't currently consider the hierarchy
      has_filter "edam_#{property.to_s.singularize}": Seek::Filtering::Filter.new(
        value_field: 'sample_controlled_vocab_terms.label',
        joins: ["edam_#{property.to_s.singularize}_values".to_sym]
      )
    end
  end

  module InstanceMethods
    private

    def edam_vocab(property)
      SampleControlledVocab::SystemVocabs.send("edam_#{property}_controlled_vocab")
    end

    # the topics can be an array or comma seperated list of either labels or IRI's
    def associate_edam_values(vals, property)
      vocab = edam_vocab(property)
      values = Array(vals.split(',').flatten).map do |value|
        value = value.strip
        vocab.sample_controlled_vocab_terms.find_by_label(value) ||
          vocab.sample_controlled_vocab_terms.find_by_iri(value)
      end.compact.uniq

      annotations = send("edam_#{property}_annotations")

      annotations.delete_all
      values.map do |annotation|
        annotations.build(source: User.current_user, value: annotation)
      end

      values
    end

    def edam_labels(property)
      edam_values(property).pluck(:label)
    end

    def edam_values(property)
      send("edam_#{property.to_s.singularize}_values")
    end
  end
end
