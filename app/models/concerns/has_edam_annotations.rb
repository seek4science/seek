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

      if @supported_edam_properties.include?(:topics)
        has_annotation_type :edam_topics
        has_many :edam_topic_values, through: :edam_topics_annotations, source: :value,
                                     source_type: 'SampleControlledVocabTerm'

        # this is needed, because it overrides a previously 'defined' method from has_annotation_type
        # the topics  vals can be an array or comma seperated list of either labels or IRI's
        define_method :edam_topics= do |vals|
          associate_edam_values vals, :topics
        end

        define_method :edam_topic_labels do
          edam_topic_values.pluck(:label)
        end

        # INDEX filters. Unfortunately, these won't currently consider the hierarchy
        has_filter edam_topic: Seek::Filtering::Filter.new(
          value_field: 'sample_controlled_vocab_terms.label',
          joins: [:edam_topic_values]
        )
        if Seek::Config.solr_enabled
          searchable(auto_index: false) do
            text :edam_topics do
              edam_topic_labels
            end
          end
        end
      end

      if @supported_edam_properties.include?(:operations)
        has_annotation_type :edam_operations
        has_many :edam_operation_values, through: :edam_operations_annotations, source: :value,
                                         source_type: 'SampleControlledVocabTerm'

        # this is needed, because it overrides a previously 'defined' method from has_annotation_type
        # the operation vals can be an array or comma seperated list of either labels or IRI's
        define_method :edam_operations= do |vals|
          associate_edam_values vals, :operations
        end

        define_method :edam_operation_labels do
          edam_operation_values.pluck(:label)
        end

        has_filter edam_operation: Seek::Filtering::Filter.new(
          value_field: 'sample_controlled_vocab_terms.label',
          joins: [:edam_operation_values]
        )

        if Seek::Config.solr_enabled
          searchable(auto_index: false) do
            text :edam_operations do
              edam_operation_labels
            end
          end
        end
      end

      if @supported_edam_properties.include?(:data)
        has_annotation_type :edam_data
        has_many :edam_data_values, through: :edam_data_annotations, source: :value,
                                    source_type: 'SampleControlledVocabTerm'

        # this is needed, because it overrides a previously 'defined' method from has_annotation_type
        # the data vals can be an array or comma seperated list of either labels or IRI's
        define_method :edam_data= do |vals|
          associate_edam_values vals, :data
        end

        define_method :edam_data_labels do
          edam_data_values.pluck(:label)
        end

        has_filter edam_data: Seek::Filtering::Filter.new(
          value_field: 'sample_controlled_vocab_terms.label',
          joins: [:edam_data_values]
        )

        if Seek::Config.solr_enabled
          searchable(auto_index: false) do
            text :edam_data do
              edam_data_labels
            end
          end
        end
      end

      if @supported_edam_properties.include?(:formats)
        has_annotation_type :edam_formats
        has_many :edam_format_values, through: :edam_formats_annotations, source: :value,
                                      source_type: 'SampleControlledVocabTerm'

        # this is needed, because it overrides a previously 'defined' method from has_annotation_type
        # the format vals can be an array or comma seperated list of either labels or IRI's
        define_method :edam_formats= do |vals|
          associate_edam_values vals, :formats
        end

        define_method :edam_format_labels do
          edam_format_values.pluck(:label)
        end

        has_filter edam_format: Seek::Filtering::Filter.new(
          value_field: 'sample_controlled_vocab_terms.label',
          joins: [:edam_format_values]
        )

        if Seek::Config.solr_enabled
          searchable(auto_index: false) do
            text :edam_formats do
              edam_format_labels
            end
          end
        end
      end
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

  end
end
