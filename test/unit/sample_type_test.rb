require 'test_helper'

class SampleTypeTest < ActiveSupport::TestCase

  test "validation" do
    sample_type = Factory :sample_type,:title=>"fish"
    assert sample_type.valid?
    sample_type.title=nil
    refute sample_type.valid?
    sample_type.title=""
    refute sample_type.valid?
  end

  test "test uuid generated" do
    sample_type = SampleType.new :title=>"fish"
    assert_nil sample_type.attributes["uuid"]
    sample_type.save
    assert_not_nil sample_type.attributes["uuid"]
  end

  test "samples" do
    sample_type = Factory :sample_type
    assert_empty sample_type.samples
    sample1 = Factory :sample, :sample_type=>sample_type
    sample2 = Factory :sample, :sample_type=>sample_type

    sample_type.reload
    assert_equal [sample1,sample2].sort,sample_type.samples.sort
  end

  test "associate sample attribute default order" do
    attribute1 = Factory(:simple_string_sample_attribute)
    attribute2 = Factory(:simple_string_sample_attribute)
    sample_type = Factory :sample_type
    sample_type.sample_attributes << attribute1
    sample_type.sample_attributes << attribute2
    sample_type.save!

    sample_type.reload

    assert_equal [attribute1, attribute2],sample_type.sample_attributes
  end

  test "associate sample attribute specify order" do
    attribute1 = Factory(:simple_string_sample_attribute)
    attribute2 = Factory(:simple_string_sample_attribute)
    attribute3 = Factory(:simple_string_sample_attribute)
    sample_type = Factory :sample_type
    sample_type.add_attribute(attribute3,3)
    sample_type.add_attribute(attribute2,2)
    sample_type.add_attribute(attribute1,1)
    sample_type.save!

    sample_type.reload

    assert_equal [attribute1, attribute2, attribute3],sample_type.sample_attributes
  end



end
