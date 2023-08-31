require 'test_helper'

class ObservedVariableSetsTest < ActiveSupport::TestCase
    
    test 'factory' do
        set = FactoryBot.build(:observed_variable_set, title: 'my set')
        assert_equal 'my set', set.title 
        refute_nil set.contributor       
        assert_difference('ObservedVariableSet.count') do
            assert_difference('ObservedVariable.count', 1) do
                assert set.save
            end
        end
        assert_equal 1, set.observed_variables.count
        assert_equal 'the variable', set.observed_variables.first.variable_id

        assert_difference('ObservedVariableSet.count') do
            assert_difference('ObservedVariable.count', 1) do
                FactoryBot.create(:observed_variable_set)
            end
        end
    end

    test 'link to variables' do
        set = ObservedVariableSet.new(title:'a set')
        var1 = set.observed_variables.build(variable_id: 'var 1')
        var2 = set.observed_variables.build(variable_id: 'var 2')
        assert_difference('ObservedVariableSet.count') do
            assert_difference('ObservedVariable.count', 2) do
                assert set.save
            end
        end
        set.reload
        var1.reload        
        var2.reload
        assert_equal [var1,var2],set.observed_variables
        assert_equal set, var1.observed_variable_set
        assert_equal set, var2.observed_variable_set
    end

end