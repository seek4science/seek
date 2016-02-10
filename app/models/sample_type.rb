class SampleType < ActiveRecord::Base
  attr_accessible :attr_definitions, :title, :uuid

  acts_as_uniquely_identifiable

  has_many :samples

  validates :title, presence: true

  class SampleAttribute
    attr_reader :name, :attribute_type

    def initialize(options = {})
      options[:required] ||= false
      options[:regexp] ||= /.*/
      @name = options[:name]
      @attribute_type = SampleAttributeType.new(options[:base_type], options[:regexp])
      @required = options[:required]
    end

    def required?
      @required
    end

    def validate_value?(value)
      return false if required? && value.blank?
      (value.blank? && !required?) || attribute_type.validate_value?(value)
    end

    def valid?
      name.is_a?(String) && attribute_type.is_a?(SampleAttributeType) && attribute_type.valid? && required?.in?([true, false])
    end
  end

  class SampleAttributeType
    ALLOWED_TYPES = [Integer, Numeric, Float, String]
    attr_reader :base_type, :regexp

    def initialize(base_type, regexp = /.*/)
      @base_type = base_type
      @regexp = regexp
    end

    def valid?
      ALLOWED_TYPES.include?(base_type) && regexp.is_a?(Regexp)
    end

    def validate_value?(value)
      value.is_a?(base_type) && (value.to_s =~ regexp)
    end

    def as_json(_options=nil)
      { base_type: base_type.name, regexp: regexp.inspect }
    end
  end
end
