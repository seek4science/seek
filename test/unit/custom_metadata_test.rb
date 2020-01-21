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

  test 'mass assign data' do
    cm = simple_test_object
    date = Time.now.to_s
    refute cm.valid?
    cm.update_attributes(data: { name: 'Fred', age: 25, date:date })
    assert cm.valid?
    assert_equal 'Fred',cm.get_attribute_value('name')
    assert_equal 25,cm.get_attribute_value('age')
    assert_equal date,cm.get_attribute_value('date')

    # also handles symbols
    assert_equal 'Fred',cm.get_attribute_value(:name)
    assert_equal 25,cm.get_attribute_value(:age)
    assert_equal date,cm.get_attribute_value(:date)
  end

  private

  def simple_test_object
    CustomMetadata.new(custom_metadata_type: Factory.build(:simple_investigation_custom_metadata_type), item: Factory(:investigation))
  end

end