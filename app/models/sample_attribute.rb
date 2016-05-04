class SampleAttribute < ActiveRecord::Base

  METHOD_PREFIX = '__sample_data_'

  attr_accessible :sample_attribute_type_id, :title, :required, :sample_attribute_type, :pos, :sample_type_id,
                  :_destroy, :sample_type, :unit, :unit_id, :is_title, :template_column_index

  belongs_to :sample_attribute_type
  belongs_to :sample_type, inverse_of: :sample_attributes
  belongs_to :unit

  validates :title, :sample_attribute_type, presence: true
  validates :sample_type, presence: true

  before_save :generate_accessor_name
  before_save :default_pos, :check_required_against_is_title

  scope :title_attributes, where(is_title: true)

  def title=(title)
    super
    generate_accessor_name
    self.title
  end

  def validate_value?(value)
    return false if required? && value.blank?
    (value.blank? && !required?) || sample_attribute_type.validate_value?(value)
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

  def check_required_against_is_title
    self.required = required? || is_title?
    true
  end
end
