require 'test_helper'

class CustomMetadataTest < ActiveSupport::TestCase

  test 'initialise' do
    cm = simple_test_object
    cm.set_attribute_value('name','fred')

    assert cm.valid?
    cm.save!
  end

  test 'set and get attribute value' do
    cm = simple_test_object
    assert_nil cm.get_attribute_value('name')
    cm.set_attribute_value('name','fred')
    assert_equal 'fred', cm.get_attribute_value('name')

    cm.save!
    cm = CustomMetadata.find(cm.id)
    assert_equal 'fred', cm.get_attribute_value('name')
  end

  test 'validate values' do
    cm = simple_test_object
    refute cm.valid?
    cm.set_attribute_value('name','bob')
    assert cm.valid?
    cm.set_attribute_value('age','not a number')
    refute cm.valid?
    cm.set_attribute_value('age','78')
    assert cm.valid?
    cm.set_attribute_value('date','not a date')
    refute cm.valid?
    cm.set_attribute_value('date',Time.now.to_s)
    assert cm.valid?
  end

  private

  def simple_test_object
    cm = CustomMetadata.new(item: Factory(:investigation))
    cm.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'age', sample_attribute_type: Factory(:integer_sample_attribute_type))
    cm.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'name', required:true, sample_attribute_type: Factory(:string_sample_attribute_type))
    cm.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'date', sample_attribute_type: Factory(:datetime_sample_attribute_type))
    cm
  end

end