class SampleType < ActiveRecord::Base

  attr_accessible :attr_definitions, :title, :uuid

  acts_as_uniquely_identifiable

  has_many :samples

  validates :title, presence: true

  class SampleAttribute
    ALLOWED_TYPES = %w(int string url)
    attr_reader :name,:type
    def initialize(options={})
      options[:required] ||= false
      @name = options[:name]
      @type = options[:type]
      @required = options[:required]
    end

    def required?
      @required
    end

    def validate_value?(value)
      (!@required || !value.blank?)
    end

    def valid?
      name.is_a?(String) && type && ALLOWED_TYPES.include?(type) && required?.in?([true,false])
    end

  end

end
