require 'test_helper'

class CustomMetadataAttributeTest < ActiveSupport::TestCase

  test 'initialize' do
    attribute = CustomMetadataAttribute.new title: 'fish', sample_attribute_type: Factory(:integer_sample_attribute_type)
    assert_equal 'fish', attribute.title
    assert_equal 'Integer', attribute.sample_attribute_type.base_type
    refute attribute.required?

    attribute = CustomMetadataAttribute.new title: 'fish', required: true, sample_attribute_type: Factory(:string_sample_attribute_type)
    assert_equal 'fish', attribute.title
    assert_equal 'String', attribute.sample_attribute_type.base_type
    assert attribute.required?
  end

  test 'validate value - without required' do
    attribute = CustomMetadataAttribute.new title: 'fish', sample_attribute_type: Factory(:integer_sample_attribute_type)
    assert attribute.validate_value?(1)
    assert attribute.validate_value?('1')
    refute attribute.validate_value?('frog')
    refute attribute.validate_value?('1.1')
    refute attribute.validate_value?(1.1)
    assert attribute.validate_value?(nil)
    assert attribute.validate_value?('')

    attribute = CustomMetadataAttribute.new title: 'fish', sample_attribute_type: Factory(:string_sample_attribute_type)
    assert attribute.validate_value?('funky fish 123')
    assert attribute.validate_value?(nil)
    assert attribute.validate_value?('')

    refute attribute.validate_value?(1)

    attribute = CustomMetadataAttribute.new title: 'fish', sample_attribute_type: Factory(:string_sample_attribute_type, regexp: 'yyy')
    assert attribute.validate_value?('yyy')
    assert attribute.validate_value?('')
    assert attribute.validate_value?(nil)
    assert attribute.validate_value?('')
    refute attribute.validate_value?(1)
    refute attribute.validate_value?('xxx')

    attribute = CustomMetadataAttribute.new title: 'fish', sample_attribute_type: Factory(:float_sample_attribute_type)
    assert attribute.validate_value?(1.0)
    assert attribute.validate_value?(1.2)
    assert attribute.validate_value?(0.78)
    assert attribute.validate_value?('0.78')
    assert attribute.validate_value?(nil)
    assert attribute.validate_value?('')

    refute attribute.validate_value?('fish')
    refute attribute.validate_value?('2 Feb 2015')

    assert attribute.validate_value?(1)
    assert attribute.validate_value?('1')

    attribute = CustomMetadataAttribute.new title: 'fish', sample_attribute_type: Factory(:datetime_sample_attribute_type)
    assert attribute.validate_value?('2 Feb 2015')
    assert attribute.validate_value?('Thu, 11 Feb 2016 15:39:55 +0000')
    assert attribute.validate_value?('2016-02-11T15:40:14+00:00')
    assert attribute.validate_value?(DateTime.parse('2 Feb 2015'))
    assert attribute.validate_value?(DateTime.now)
    refute attribute.validate_value?(1)
    refute attribute.validate_value?(1.2)
    refute attribute.validate_value?('30 Feb 2015')
  end

  test 'validate value with required' do
    attribute = CustomMetadataAttribute.new title: 'fish', sample_attribute_type: Factory(:integer_sample_attribute_type), required: true
    assert attribute.validate_value?(1)
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')

    attribute = CustomMetadataAttribute.new title: 'fish', sample_attribute_type: Factory(:string_sample_attribute_type), required: true
    assert attribute.validate_value?('string')
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')

    attribute = CustomMetadataAttribute.new title: 'fish', sample_attribute_type: Factory(:float_sample_attribute_type), required: true
    assert attribute.validate_value?(1.2)
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')

    attribute = CustomMetadataAttribute.new title: 'fish', sample_attribute_type: Factory(:datetime_sample_attribute_type), required: true
    assert attribute.validate_value?('9 Feb 2015')
    refute attribute.validate_value?(nil)
    refute attribute.validate_value?('')
  end

  test 'accessor name' do
    attribute = CustomMetadataAttribute.new title: 'fish', sample_attribute_type: Factory(:datetime_sample_attribute_type)
    assert_equal 'fish', attribute.accessor_name

    attribute = CustomMetadataAttribute.new title: 'fish pie', sample_attribute_type: Factory(:datetime_sample_attribute_type)
    assert_equal 'fish pie', attribute.accessor_name
  end

  test 'label defaults to humanized title' do
    attribute = CustomMetadataAttribute.new title: 'fish_soup', sample_attribute_type: Factory(:datetime_sample_attribute_type)
    assert_nil attribute[:label]
    assert_equal 'Fish soup',attribute.label
    attribute.label = "Apple pie"
    assert_equal 'Apple pie',attribute.label
    assert_equal 'fish_soup',attribute.title

    attribute.label = nil
    attribute.title = nil

    assert_nil attribute.label

  end


end