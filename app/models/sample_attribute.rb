class SampleAttribute < ActiveRecord::Base

  METHOD_PREFIX = '__sample_data_'

  attr_accessible :sample_attribute_type_id, :title, :required, :sample_attribute_type, :pos, :sample_type_id,
                  :_destroy, :sample_type, :unit, :unit_id, :is_title, :template_column_index

  belongs_to :sample_attribute_type
  belongs_to :sample_type, inverse_of: :sample_attributes
  belongs_to :unit
  belongs_to :sample_controlled_vocab

  validates :title, :sample_attribute_type, presence: true
  validates :sample_type, presence: true

  #validates that the attribute type is CV if vocab is set, and vice-versa
  validate :sample_controlled_vocab_and_attribute_type_consistency

  before_save :generate_accessor_name
  before_save :default_pos, :force_required_when_is_title

  scope :title_attributes, where(is_title: true)

  def title=(title)
    super
    generate_accessor_name
    self.title
  end

  def validate_value?(value)
    return false if required? && value.blank?
    (value.blank? && !required?) || sample_attribute_type.validate_value?(value,controlled_vocab:sample_controlled_vocab)
  end

  # The method name used to get this attribute via a method call
  def method_name
    METHOD_PREFIX + hash_key
  end

  # The key used to address this attribute in the sample's JSON blob
  def hash_key
    title.parameterize.underscore
  end

  def required?
    super || is_title?
  end

  def pre_process_value(value)
    sample_attribute_type.pre_process_value(value)
  end

  private

  def generate_accessor_name
    self.accessor_name = self.hash_key
  end

  # if not set, takes the next value for that sample type
  def default_pos
    self.pos ||= (self.class.where(sample_type_id: sample_type_id).maximum(:pos) || 0) + 1
  end

  def force_required_when_is_title
    #forces required to be true if it is a title
    self.required = required? || is_title?
    true
  end

  def sample_controlled_vocab_and_attribute_type_consistency
    if sample_attribute_type && sample_controlled_vocab && sample_attribute_type.base_type!='CV'
      errors.add(:sample_attribute_type, "Attribute type must be CV if controlled vocabulary set")
    end
    if sample_attribute_type && sample_attribute_type.base_type=='CV' && sample_controlled_vocab.nil?
      errors.add(:sample_controlled_vocab, "Controlled vocabulary must be set if attribute type is CV")
    end
  end
end
