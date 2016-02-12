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

  test "sets up accessor methods" do
    sample = Factory(:sample, :sample_type=>Factory(:patient_sample_type))
    sample = Sample.find(sample.id)
    refute_nil sample.sample_type

    assert_respond_to sample,:full_name
    assert_respond_to sample,:full_name=
    assert_respond_to sample,:age
    assert_respond_to sample,:age=
    assert_respond_to sample,:postcode
    assert_respond_to sample,:postcode=
    assert_respond_to sample,:weight
    assert_respond_to sample,:weight=


    #doesn't affect all sample classes
    sample = Factory(:sample,:sample_type=>Factory(:sample_type))
    refute_respond_to sample,:full_name
    refute_respond_to sample,:full_name=
    refute_respond_to sample,:age
    refute_respond_to sample,:age=
    refute_respond_to sample,:postcode
    refute_respond_to sample,:postcode=
    refute_respond_to sample,:weight
    refute_respond_to sample,:weight=
  end

  test "sets up accessor methods when assigned" do
    sample = Sample.new :title=>"testing"
    sample.sample_type = Factory(:patient_sample_type)

    assert_respond_to sample,:full_name
    assert_respond_to sample,:full_name=
    assert_respond_to sample,:age
    assert_respond_to sample,:age=
    assert_respond_to sample,:postcode
    assert_respond_to sample,:postcode=
    assert_respond_to sample,:weight
    assert_respond_to sample,:weight=

  end

  test "removes accessor methods with new assigned type" do
    sample = Sample.new :title=>"testing"
    sample.sample_type = Factory(:patient_sample_type)

    assert_respond_to sample,:full_name
    assert_respond_to sample,:full_name=

    sample.sample_type = Factory(:sample_type)

    refute_respond_to sample,:full_name
    refute_respond_to sample,:full_name=
    refute_respond_to sample,:age
    refute_respond_to sample,:age=
    refute_respond_to sample,:postcode
    refute_respond_to sample,:postcode=
    refute_respond_to sample,:weight
    refute_respond_to sample,:weight=

  end

end
