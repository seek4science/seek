require 'test_helper'

class SampleTest < ActiveSupport::TestCase

  test "validation" do
    sample = Factory :sample,:title=>"fish", :sample_type=>Factory(:sample_type)
    assert sample.valid?
    sample.title=nil
    refute sample.valid?
    sample.title=""
    refute sample.valid?

    sample.title="fish"
    sample.sample_type=nil
    refute sample.valid?
  end

  test "test uuid generated" do
    sample = Sample.new :title=>"fish"
    assert_nil sample.attributes["uuid"]
    sample.save
    assert_not_nil sample.attributes["uuid"]
  end

end
