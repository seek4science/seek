module HasEdamAnnotations
  extend ActiveSupport::Concern

  class_methods do
    def has_edam_annotations
      has_annotation_type :edam_topics
      has_many :edam_topic_values, through: :edam_topics_annotations, source: :value,
                                   source_type: 'SampleControlledVocabTerm'
      include InstanceMethods

      # this is needed, because it overrides a previously 'defined' method from has_annotation_type
      define_method :edam_topics= do |vals|
        associate_edam_topics vals
      end
    end
  end

  module InstanceMethods
    def edam_topics_vocab
      SampleControlledVocab::SystemVocabs.edam_topics_controlled_vocab
    end

    # the topics can be an array or comma seperated list of either labels or IRI's
    def associate_edam_topics(vals)
      topic_values = Array(vals.split(',')).map do |value|
        edam_topics_vocab.sample_controlled_vocab_terms.find_by_label(value) ||
          edam_topics_vocab.sample_controlled_vocab_terms.find_by_iri(value)
      end.compact.uniq

      edam_topics_annotations.delete_all
      self.edam_topics_annotations = topic_values.map do |topic|
        edam_topics_annotations.build(source: User.current_user, value: topic)
      end

      edam_topics
    end
  end
end
