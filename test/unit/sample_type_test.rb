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




end
