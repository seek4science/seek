require 'test_helper'

class SampleTest < ActiveSupport::TestCase

  test "validation" do
    sample = Factory :sample,:title=>"fish"
    assert sample.valid?
    sample.title=nil
    refute sample.valid?
    sample.title=""
    refute sample.valid?
  end

  test "test uuid generated" do
    sample = Sample.new :title=>"fish"
    assert_nil sample.attributes["uuid"]
    sample.save
    assert_not_nil sample.attributes["uuid"]
  end

end
