require 'test_helper'

class TreatmentTest < ActiveSupport::TestCase
  test "validation of sample required" do
    t = Treatment.new
    refute t.valid?
    sample = Factory(:sample)
    t.sample=sample
    assert t.valid?
  end
end