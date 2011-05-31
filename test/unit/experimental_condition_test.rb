require 'test_helper'

class ExperimentalConditionTest < ActiveSupport::TestCase
  fixtures :all
  test 'should create experimental condition with the concentration of the compound' do
    measured_item = measured_items(:concentration)
    unit = units(:gram)
    compound = compounds(:compound_glucose)
    sop = sops(:editable_sop)
    ec = ExperimentalCondition.new(:sop => sop, :measured_item => measured_item, :start_value => 1, :end_value => 10, :unit => unit, :substance => compound)
    assert ec.save, "should create the new experimental condition with the concentration of the compound "
  end

  test 'should not create experimental condition with the concentration of no substance' do
    measured_item = measured_items(:concentration)
    unit = units(:gram)
    sop = sops(:editable_sop)
    ec = ExperimentalCondition.new(:sop => sop, :measured_item => measured_item, :start_value => 1, :end_value => 10, :unit => unit, :substance => nil)
    assert !ec.save, "shouldn't create experimental condition with concentration of no substance"
  end

  test 'should create experimental condition with the none concentration item and no substance' do
    measured_item = measured_items(:time)
    unit = units(:second)
    sop = sops(:editable_sop)
    ec = ExperimentalCondition.new(:sop => sop, :measured_item => measured_item, :start_value => 1, :end_value => 10, :unit => unit, :substance => nil)
    p ec
    assert ec.save, "should create experimental condition  of the none concentration item and no substance"
  end

  test "should create experimental condition with the concentration of the compound's synonym" do
    measured_item = measured_items(:concentration)
    unit = units(:gram)
    synonym = synonyms(:glucose_synonym)
    sop = sops(:editable_sop)
    ec= ExperimentalCondition.new(:sop => sop, :measured_item => measured_item, :start_value => 1, :end_value => 10, :unit => unit, :substance => synonym)
    assert ec.save, "should create the new experimental condition with the concentration of the compound's synonym "
  end
end
