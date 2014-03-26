require 'test_helper'

class TreatmentTest < ActiveSupport::TestCase
  test "validation of sample required" do
    t = Treatment.new
    refute t.valid?
    sample = Factory(:sample)
    t.sample=sample
    assert t.valid?
  end

  test "association with measured item" do
    mi = Factory(:measured_item)
    t = Factory(:treatment)

    t.measured_item = mi
    t.save!
    t.reload
    assert_equal mi, t.measured_item
    assert_equal mi, t.treatment_type
  end

  test "association with compound" do
    c = Factory(:compound)
    t = Factory(:treatment)
    t.compound = c
    t.save!
    t.reload
    assert_equal c,t.compound
  end
end