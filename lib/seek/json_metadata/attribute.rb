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

        delegate :controlled_vocab?, :seek_cv_list?, :seek_sample?, :seek_sample_multi?, :seek_strain?, :seek_resource?, :linked_custom_metadata?, to: :sample_attribute_type, allow_nil: true
      end

      # checks whether the value is blank against the attribute type and base type
      def test_blank?(value)
        sample_attribute_type.test_blank?(value)
      end

      def validate_value?(value)
        return false if required? && test_blank?(value)
        return true if test_blank?(value) && !required?

        sample_attribute_type.validate_value?(value, required: required?,
                                                     controlled_vocab: sample_controlled_vocab,
                                                     linked_sample_type: linked_sample_type)
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

      def pre_process_value(value)
        sample_attribute_type.pre_process_value(value, controlled_vocab: sample_controlled_vocab, linked_sample_type: linked_sample_type)
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
          errors.add(:seek_sample_multi, 'Linked Sample Type must be set if attribute type is Registered Sample (multiple)')
        end
      end
    end
  end
end
