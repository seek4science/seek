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

        delegate :controlled_vocab?, :seek_sample?, :seek_strain?, :seek_resource?, to: :sample_attribute_type, allow_nil: true
      end

      def validate_value?(value)
        return false if required? && value.blank?
        (value.blank? && !required?) || sample_attribute_type.validate_value?(value, required: required?,
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

      # The method name used to get this attribute via a method call
      def method_name
        Seek::JSONMetadata::METHOD_PREFIX + accessor_name
      end

      def pre_process_value(value)
        sample_attribute_type.pre_process_value(value, controlled_vocab: sample_controlled_vocab, linked_sample_type: linked_sample_type)
      end

      private

      def sample_controlled_vocab_and_attribute_type_consistency
        if sample_attribute_type && sample_controlled_vocab && !controlled_vocab?
          errors.add(:sample_attribute_type, 'Attribute type must be CV if controlled vocabulary set')
        end
        if controlled_vocab? && sample_controlled_vocab.nil?
          errors.add(:sample_controlled_vocab, 'Controlled vocabulary must be set if attribute type is CV')
        end
      end

      def linked_sample_type_and_attribute_type_consistency
        if sample_attribute_type && linked_sample_type && !seek_sample?
          errors.add(:sample_attribute_type, 'Attribute type must be SeekSample if linked sample type set')
        end
        if seek_sample? && linked_sample_type.nil?
          errors.add(:sample_controlled_vocab, 'Linked Sample Type must be set if attribute type is SeekSample')
        end
      end
    end
  end
end
