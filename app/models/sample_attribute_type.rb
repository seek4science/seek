class SampleAttributeType < ActiveRecord::Base
  attr_accessible :base_type, :regexp, :title

  validates :title, :base_type, :regexp, presence: true
  validate :validate_allowed_type, :validate_regular_expression

  before_save :set_defaults_attributes
  after_initialize :set_defaults_attributes

  scope :primitive_string_types, where(base_type: 'String', regexp: '.*')

  BASE_TYPE_AND_CHECKER_MAP = {
    'Integer' => :is_integer?,
    'Float' => :is_float?,
    'String' => :is_string?,
    'DateTime' => :is_datetime?,
    'Text' => :is_string?
  }

  def validate_allowed_type
    unless SampleAttributeType.allowed_base_types.include?(base_type)
      errors.add(:base_type, 'Not a valid base type')
    end
  end

  def self.allowed_base_types
    BASE_TYPE_AND_CHECKER_MAP.keys
  end

  def validate_value?(value)
    check_value_against_base_type(value) && check_value_against_regular_expression(value)
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

  def check_value_against_base_type(value)
    checker = BASE_TYPE_AND_CHECKER_MAP[base_type]
    begin
      send(checker, value)
    rescue
      return false
    end
    true
  end

  # CHECKERS for types, these should raise an exception if the type doesn't match

  # value can be Integer or String
  def is_integer?(value)
    fail 'Not an integer' unless (Integer(value).to_s == value.to_s)
  end

  def is_string?(value)
    fail 'Not a string' unless value.is_a?(String)
  end

  def is_float?(value)
    fail 'Not a float' unless (Float(value).to_s == value.to_s)
  end

  def is_datetime?(value)
    fail 'Not a date time' unless DateTime.parse(value.to_s)
  end
end
