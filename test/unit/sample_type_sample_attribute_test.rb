require 'test_helper'

class SampleTypeSampleAttributeTest < ActiveSupport::TestCase

  test 'default pos' do
    sample_type = Factory(:sample_type)
    sample_type2 = Factory(:sample_type)

    join = SampleTypeSampleAttribute.new(:sample_type=>sample_type,:sample_attribute=>Factory(:simple_string_sample_attribute))
    join.save!
    join = SampleTypeSampleAttribute.where(:sample_type_id=>join.sample_type_id,:sample_attribute_id=>join.sample_attribute_id).first
    assert_equal 1,join.pos

    join = SampleTypeSampleAttribute.new(:sample_type=>sample_type,:sample_attribute=>Factory(:simple_string_sample_attribute))
    join.save!
    join = SampleTypeSampleAttribute.where(:sample_type_id=>join.sample_type_id,:sample_attribute_id=>join.sample_attribute_id).first
    assert_equal 2,join.pos

    join = SampleTypeSampleAttribute.new(:sample_type=>sample_type,:sample_attribute=>Factory(:simple_string_sample_attribute))
    join.save!
    join = SampleTypeSampleAttribute.where(:sample_type_id=>join.sample_type_id,:sample_attribute_id=>join.sample_attribute_id).first
    assert_equal 3,join.pos

    join = SampleTypeSampleAttribute.new(:sample_type=>sample_type2,:sample_attribute=>Factory(:simple_string_sample_attribute))
    join.save!
    join = SampleTypeSampleAttribute.where(:sample_type_id=>join.sample_type_id,:sample_attribute_id=>join.sample_attribute_id).first
    assert_equal 1,join.pos

    join = SampleTypeSampleAttribute.new(:sample_type=>sample_type2,:sample_attribute=>Factory(:simple_string_sample_attribute),:pos=>6)
    join.save!
    join = SampleTypeSampleAttribute.where(:sample_type_id=>join.sample_type_id,:sample_attribute_id=>join.sample_attribute_id).first
    assert_equal 6,join.pos

  end


end
