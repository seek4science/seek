require 'test_helper'

class ObservedVariablesTest < ActiveSupport::TestCase

    test 'factory' do
        var = FactoryBot.build(:observed_variable, variable_id:'my var')
        assert_equal 'my var',var.variable_id
        assert_difference('ObservedVariable.count', 1) do
            assert var.save
        end        
    end

end