module HasEdamAnnotations
  extend ActiveSupport::Concern

  included do
    def supports_edam_annotations?
      respond_to?(:edam_topics) && respond_to?(:edam_operations)
    end

    def edam_annotations?
      return false unless supports_edam_annotations?
      edam_topics.any? || edam_operations.any?
    end
  end

  class_methods do
    def has_edam_annotations
      include InstanceMethods
      include Search
      has_annotation_type :edam_topics
      has_many :edam_topic_values, through: :edam_topics_annotations, source: :value,
                                   source_type: 'SampleControlledVocabTerm'
      has_annotation_type :edam_operations
      has_many :edam_operation_values, through: :edam_operations_annotations, source: :value,
                                       source_type: 'SampleControlledVocabTerm'

      # this is needed, because it overrides a previously 'defined' method from has_annotation_type
      # the topics  vals can be an array or comma seperated list of either labels or IRI's
      define_method :edam_topics= do |vals|
        associate_edam_topics vals
      end

      # this is needed, because it overrides a previously 'defined' method from has_annotation_type
      # the operation vals can be an array or comma seperated list of either labels or IRI's
      define_method :edam_operations= do |vals|
        associate_edam_operations vals
      end

      # INDEX filters. Unfortunately, these won't currently consider the hierarchy
      has_filter edam_topic: Seek::Filtering::Filter.new(
        value_field: 'sample_controlled_vocab_terms.label',
        joins: [:edam_topic_values]
      )

      has_filter edam_operation: Seek::Filtering::Filter.new(
        value_field: 'sample_controlled_vocab_terms.label',
        joins: [:edam_operation_values]
      )
    end
  end

  module Search
    def self.included(klass)
      klass.class_eval do
        if Seek::Config.solr_enabled
          searchable(auto_index: false) do
            text :edam_topics do
              edam_topic_labels
            end
            text :edam_operations do
              edam_operation_labels
            end
          end
        end
      end
    end
  end

  module InstanceMethods
    def edam_topics_vocab
      SampleControlledVocab::SystemVocabs.edam_topics_controlled_vocab
    end

    def edam_operations_vocab
      SampleControlledVocab::SystemVocabs.edam_operations_controlled_vocab
    end

    def edam_topic_labels
      edam_topic_values.pluck(:label)
    end

    def edam_operation_labels
      edam_operation_values.pluck(:label)
    end

    private

    # the topics can be an array or comma seperated list of either labels or IRI's
    def associate_edam_topics(vals)
      topic_values = Array(vals.split(',').flatten).map do |value|
        value = value.strip
        edam_topics_vocab.sample_controlled_vocab_terms.find_by_label(value) ||
          edam_topics_vocab.sample_controlled_vocab_terms.find_by_iri(value)
      end.compact.uniq

      edam_topics_annotations.delete_all
      self.edam_topics_annotations = topic_values.map do |annotation|
        edam_topics_annotations.build(source: User.current_user, value: annotation)
      end

      topic_values
    end

    def associate_edam_operations(vals)
      operation_values = Array(vals.split(',').flatten).map do |value|
        value = value.strip
        edam_operations_vocab.sample_controlled_vocab_terms.find_by_label(value) ||
          edam_operations_vocab.sample_controlled_vocab_terms.find_by_iri(value)
      end.compact.uniq

      edam_operations_annotations.delete_all
      self.edam_operations_annotations = operation_values.map do |annotation|
        edam_operations_annotations.build(source: User.current_user, value: annotation)
      end

      operation_values
    end
  end
end
