require 'test_helper'

class ExperimentalConditionLinkTest < ActiveSupport::TestCase
  fixtures :all

  test 'should create a experimental_condition_link' do
    experimental_condition_link = ExperimentalConditionLink.new(substance: compounds(:compound_glucose), experimental_condition: experimental_conditions(:experimental_condition_concentration_glucose))
    assert experimental_condition_link.save!
  end

  test 'should not create experimental_condition_link without substance or experimental_condition' do
    experimental_condition_link = ExperimentalConditionLink.new(substance: compounds(:compound_glucose))
    assert !experimental_condition_link.save
    experimental_condition_link = ExperimentalConditionLink.new(experimental_condition: experimental_conditions(:experimental_condition_concentration_glucose))
    assert !experimental_condition_link.save
  end
end
