require 'test_helper'

class SampleAttributeTest < ActiveSupport::TestCase

  test "sample_attribute initialize" do
    attribute = SampleAttribute.new title:"fish",sample_attribute_type:Factory(:integer_sample_attribute_type)
    assert_equal "fish",attribute.title
    assert_equal "Integer", attribute.sample_attribute_type.base_type
    refute attribute.required?

    attribute = SampleAttribute.new title:"fish",required:true,sample_attribute_type:Factory(:string_sample_attribute_type)
    assert_equal "fish",attribute.title
    assert_equal "String", attribute.sample_attribute_type.base_type
    assert attribute.required?
  end

  test "valid?" do
    attribute = SampleAttribute.new title:"fish",sample_attribute_type:Factory(:integer_sample_attribute_type)
    assert attribute.valid?

    attribute = SampleAttribute.new title:"fish",sample_attribute_type:Factory(:string_sample_attribute_type,regexp:"xxx")
    assert attribute.valid?

    attribute = SampleAttribute.new title:"fish"
    refute attribute.valid?
    attribute = SampleAttribute.new sample_attribute_type:Factory(:integer_sample_attribute_type)
    refute attribute.valid?
    attribute = SampleAttribute.new
    refute attribute.valid?
  end

  test "sample attribute validate value" do
    attribute = SampleAttribute.new title:"fish",sample_attribute_type:Factory(:integer_sample_attribute_type)
    assert attribute.validate_value?(1)
    refute attribute.validate_value?("frog")

    assert attribute.validate_value?(nil)
    assert attribute.validate_value?('')

    attribute = SampleAttribute.new title:"fish",required:true,sample_attribute_type:Factory(:string_sample_attribute_type)
    refute attribute.validate_value?(1)
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')

    attribute = SampleAttribute.new title:"fish",sample_attribute_type:Factory(:string_sample_attribute_type,regexp:"yyy")
    assert attribute.validate_value?('yyy')
    assert attribute.validate_value?('')
    assert attribute.validate_value?(nil)
    refute attribute.validate_value?(1)
    refute attribute.validate_value?("xxx")
  end

end
