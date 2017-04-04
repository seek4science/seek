class SampleAttributeType < ActiveRecord::Base
  # attr_accessible :base_type, :regexp, :title, :placeholder

  validates :title, :base_type, :regexp, presence: true
  validate :validate_allowed_type, :validate_regular_expression

  before_save :set_defaults_attributes
  after_initialize :set_defaults_attributes

  scope :primitive_string_types, -> { where(base_type: 'String', regexp: '.*') }

  def validate_allowed_type
    unless Seek::Samples::BaseType.valid?(base_type)
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

  def validate_value?(value, additional_options = {})
    check_value_against_base_type(value, additional_options) && check_value_against_regular_expression(value)
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
    /#{regexp}/m
  end

  def check_value_against_regular_expression(value)
    match = regular_expression.match(value.to_s)
    match && (match.to_s == value.to_s)
  end

  def check_value_against_base_type(value, additional_options)
    base_type_handler(additional_options).validate_value?(value)
  end

  def pre_process_value(value, additional_options)
    base_type_handler(additional_options).convert(value)
  end

  def controlled_vocab?
    base_type == Seek::Samples::BaseType::CV
  end

  def seek_sample?
    base_type == Seek::Samples::BaseType::SEEK_SAMPLE
  end

  def seek_strain?
    base_type == Seek::Samples::BaseType::SEEK_STRAIN
  end

  def base_type_handler(additional_options)
    Seek::Samples::AttributeTypeHandlers::AttributeTypeHandlerFactory.instance.for_base_type(base_type, additional_options)
  end
end
