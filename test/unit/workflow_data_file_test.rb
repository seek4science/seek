require 'test_helper'

class WorkflowDataFileTest < ActiveSupport::TestCase

  test 'dependant destroy' do
    @person = FactoryBot.create(:person)

    rel = FactoryBot.create(:test_data_workflow_data_file_relationship)
    df = FactoryBot.create(:data_file, contributor: @person)
    wf = nil

    assert_difference('WorkflowDataFile.count') do
      wf = FactoryBot.create(:workflow, contributor: @person, workflow_data_files: [WorkflowDataFile.new(data_file:df, workflow_data_file_relationship: rel)] )
    end

    User.with_current_user(@person.user) do
      assert_difference('WorkflowDataFile.count', -1) do
        assert_no_difference('WorkflowDataFileRelationship.count') do
          wf.destroy
        end
      end
    end

    assert_difference('WorkflowDataFile.count') do
      wf = FactoryBot.create(:workflow, contributor: @person, workflow_data_files: [WorkflowDataFile.new(data_file:df, workflow_data_file_relationship: rel)] )
    end

    User.with_current_user(@person.user) do
      assert_difference('WorkflowDataFile.count', -1) do
        assert_no_difference('WorkflowDataFileRelationship.count') do
          df.destroy
        end
      end
    end
  end

  test 'validation' do
    wf = FactoryBot.create(:workflow)
    df = FactoryBot.create(:data_file)
    wfdf = WorkflowDataFile.new(data_file: df, workflow:wf, workflow_data_file_relationship:nil)

    assert wfdf.valid?

    wfdf.data_file = nil
    refute wfdf.valid?

    wfdf.data_file = df
    wfdf.workflow = nil
    refute wfdf.valid?

    wfdf.workflow = wf
    wfdf.workflow_data_file_relationship = FactoryBot.create(:test_data_workflow_data_file_relationship)
    assert wfdf.valid?

  end


end