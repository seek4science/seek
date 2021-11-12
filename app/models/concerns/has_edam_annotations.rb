module HasEdamAnnotations
  extend ActiveSupport::Concern

  class_methods do
    def has_edam_annotations
      include InstanceMethods
      has_annotation_type :edam_topics
      has_many :edam_topic_values, through: :edam_topics_annotations, source: :value,
                                   source_type: 'SampleControlledVocabTerm'
      has_annotation_type :edam_operations
      has_many :edam_operation_values, through: :edam_operations_annotations, source: :value,
               source_type: 'SampleControlledVocabTerm'

      # this is needed, because it overrides a previously 'defined' method from has_annotation_type
      define_method :edam_topics= do |vals|
        associate_edam_topics vals
      end

      define_method :edam_operations= do |vals|
        associate_edam_operations vals
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

    # the topics can be an array or comma seperated list of either labels or IRI's
    def associate_edam_topics(vals)
      topic_values = Array(vals.split(',')).map do |value|
        edam_topics_vocab.sample_controlled_vocab_terms.find_by_label(value) ||
          edam_topics_vocab.sample_controlled_vocab_terms.find_by_iri(value)
      end.compact.uniq

      self.edam_topics_annotations.delete_all
      self.edam_topics_annotations = topic_values.map do |annotation|
        edam_topics_annotations.build(source: User.current_user, value: annotation)
      end

      topic_values
    end

    def associate_edam_operations(vals)
      operation_values = Array(vals.split(',')).map do |value|
        edam_operations_vocab.sample_controlled_vocab_terms.find_by_label(value) ||
          edam_operations_vocab.sample_controlled_vocab_terms.find_by_iri(value)
      end.compact.uniq

      self.edam_operations_annotations.delete_all
      self.edam_operations_annotations = operation_values.map do |annotation|
        edam_operations_annotations.build(source: User.current_user, value: annotation)
      end

      operation_values
    end
  end
end
