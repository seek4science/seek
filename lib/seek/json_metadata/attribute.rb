module Seek
  module JSONMetadata
    module Attribute
      extend ActiveSupport::Concern

      included do
        belongs_to :sample_attribute_type, inverse_of: table_name.to_sym
        belongs_to :sample_controlled_vocab, inverse_of: table_name.to_sym

        validates :title, presence: true
        validates :sample_attribute_type, presence: true

        # validates that the attribute type is CV if vocab is set, and vice-versa
        validate :sample_controlled_vocab_and_attribute_type_consistency

        # validates that the attribute type is SeekSample if linked_sample_type is set, and vice-versa
        validate :linked_sample_type_and_attribute_type_consistency

        delegate :controlled_vocab?, :seek_cv_list?, :seek_sample?, :seek_sample_multi?, :seek_strain?, :linked_extended_metadata?,:linked_extended_metadata_multi?, to: :sample_attribute_type, allow_nil: true
      end

      # checks whether the value is blank against the attribute type and base type
      def test_blank?(value)
        base_type_handler.test_blank?(value)
      end

      def validate_value?(value)
        return false if required? && test_blank?(value)
        return true if test_blank?(value) && !required?

        check_value_against_base_type(value) && check_value_against_regular_expression(value)
      end

      def pre_process_value(value)
        base_type_handler.convert(value)
      end

      def accessor_name
        title
      end

      def resolve(value)
        resolution = if sample_attribute_type.resolution.present? && sample_attribute_type.regexp.present?
                       value.sub(Regexp.new(sample_attribute_type.regexp), sample_attribute_type.resolution)
                     end
        resolution
      end

      def seek_resource?
        base_type_handler.is_a?(Seek::Samples::AttributeHandlers::SeekResourceAttributeHandler)
      end

      def base_type_handler
        Seek::Samples::AttributeHandlers::AttributeHandlerFactory.instance.for_attribute(self)
      end

      private

      def sample_controlled_vocab_and_attribute_type_consistency

        if sample_attribute_type && sample_controlled_vocab
          unless controlled_vocab? || seek_cv_list?
            errors.add(:sample_attribute_type, 'Attribute type must be CV if controlled vocabulary set')
          end
        end

        if controlled_vocab? && sample_controlled_vocab.nil?
          errors.add(:sample_controlled_vocab, 'Controlled vocabulary must be set if attribute type is CV')
        end

        if seek_cv_list? && sample_controlled_vocab.nil?
          errors.add(:sample_controlled_vocab, 'Controlled vocabulary must be set if attribute type is LIST')
        end

      end

      def linked_sample_type_and_attribute_type_consistency
        if sample_attribute_type && linked_sample_type && !seek_sample? && !seek_sample_multi?
          errors.add(:sample_attribute_type, 'Attribute type must be SeekSample if linked sample type set')
        end
        if seek_sample? && linked_sample_type.nil?
          errors.add(:seek_sample, 'Linked Sample Type must be set if attribute type is Registered Sample')
        elsif seek_sample_multi? && linked_sample_type.nil?
          errors.add(:seek_sample_multi, 'Linked Sample Type must be set if attribute type is Registered Sample List')
        end
      end

      def check_value_against_regular_expression(value)
        match = sample_attribute_type.regular_expression.match(value.to_s)
        match && (match.to_s == value.to_s)
      end

      def check_value_against_base_type(value)
        base_type_handler.validate_value?(value)
      end

    end
  end
end
