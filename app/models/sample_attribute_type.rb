class SampleAttributeType < ActiveRecord::Base
  attr_accessible :base_type, :regexp, :title

  validates :title, :base_type, :regexp, presence: true
  validate :validate_allowed_type, :validate_regular_expression

  before_save :set_defaults_attributes
  after_initialize :set_defaults_attributes

  scope :primitive_string_types, where(base_type: 'String', regexp: '.*')

  BASE_TYPES = %w(Integer Float String DateTime Date Text Boolean SeekStrain CV)

  def validate_allowed_type
    unless SampleAttributeType.allowed_base_types.include?(base_type)
      errors.add(:base_type, 'Not a valid base type')
    end
  end

  def self.allowed_base_types
    BASE_TYPES
  end

  def self.default
    primitive_string_types.first
  end

  def default?
    self == self.class.default
  end

  def validate_value?(value,additional_options={})
    check_value_against_base_type(value,additional_options) && check_value_against_regular_expression(value)
  end

  def as_json(_options = nil)
    { title: title, base_type: base_type, regexp: regexp }
  end

  def set_defaults_attributes
    self.regexp ||= '.*'
  end

  def validate_regular_expression
    regular_expression
  rescue RegexpError
    errors.add(:regexp, 'Not a valid regular expression')
  end

  def regular_expression
    /#{regexp}/
  end

  def check_value_against_regular_expression(value)
    match = regular_expression.match(value.to_s)
    match && match.to_s == value.to_s
  end

  def check_value_against_base_type(value,additional_options)
    base_type_handler.validate_value?(value,additional_options)
  end

  def pre_process_value(value)
    base_type_handler.convert(value)
  end

  def base_type_handler
    Seek::Samples::AttributeTypeHandlers::AttributeTypeHandlerFactory.instance.for_base_type(base_type)
  end
end
