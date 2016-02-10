class SampleType < ActiveRecord::Base

  attr_accessible :attr_definitions, :title, :uuid

  acts_as_uniquely_identifiable

  has_many :samples

  validates :title, presence: true

  class SampleAttribute

    attr_reader :name,:type

    def initialize(options={})
      options[:required] ||= false
      options[:regexp] ||= /.*/
      @name = options[:name]
      @type = SampleAttributeType.new(options[:type],options[:regexp])
      @required = options[:required]
    end

    def required?
      @required
    end

    def validate_value?(value)
      (!@required || !value.blank?)
    end

    def valid?
      name.is_a?(String) && type && type.is_a?(SampleAttributeType) && type.valid? && required?.in?([true,false])
    end
  end

  class SampleAttributeType
    ALLOWED_TYPES = [Integer,Numeric,Float,String]
    attr_reader :type, :regexp

    def initialize type, regexp=/.*/
      @type=type
      @regexp=regexp
    end

    def valid?
      ALLOWED_TYPES.include?(type) && regexp.is_a?(Regexp)
    end

    def validate_value?(value)
      value.is_a?(type) && (value.to_s =~ regexp)
    end

    def as_json
      {type:type.name,regexp:regexp.inspect}
    end
  end

end
