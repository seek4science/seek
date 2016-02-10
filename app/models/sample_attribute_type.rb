class SampleAttributeType < ActiveRecord::Base
  attr_accessible :base_type, :regexp, :title

  after_initialize :default_values

  ALLOWED_TYPES = ["Integer", "Numeric", "Float", "String"]

  validates :title, :base_type, :regexp, presence:true

  validate :check_allowed_type,:check_regular_expression

  def check_allowed_type
    unless ALLOWED_TYPES.include?(base_type)
      errors.add(:base_type,"Not a valid base type")
    end
  end

  def check_regular_expression
    begin
      regular_expression
    rescue RegexpError
      errors.add(:regexp,"Not a valid regular expression")
    end
  end

  def regular_expression
    /#{regexp}/
  end

  def default_values
    self.regexp||='.*'
  end

  def validate_value?(value)
    value.is_a?(base_type.constantize) && (value.to_s =~ regular_expression)
  end

  def as_json(_options=nil)
    { title:title, base_type: base_type, regexp: regexp }
  end
end
