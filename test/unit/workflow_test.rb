require 'test_helper'

class WorkflowTest < ActiveSupport::TestCase
  test 'validations' do
    workflow = Factory :workflow
    workflow.title = ''

    assert !workflow.valid?

    workflow.reload

  end

  test "new workflow's version is 1" do
    workflow = Factory :workflow
    assert_equal 1, workflow.version
  end

  test 'can create new version of workflow' do
    workflow = Factory :workflow
    old_attrs = workflow.attributes

    disable_authorization_checks do
      workflow.save_as_new_version('new version')
    end

    assert_equal 1, old_attrs['version']
    assert_equal 2, workflow.version

    old_attrs.delete('version')
    new_attrs = workflow.attributes
    new_attrs.delete('version')

    old_attrs.delete('updated_at')
    new_attrs.delete('updated_at')

    old_attrs.delete('created_at')
    new_attrs.delete('created_at')

    assert_equal old_attrs, new_attrs
  end

  test 'sop association' do
    workflow = Factory :workflow
    assert workflow.sops.empty?

    User.current_user = workflow.contributor
    assert_difference 'workflow.sops.count' do
      workflow.sops << Factory(:sop)
    end
  end

  test 'has uuid' do
    workflow = Factory :workflow
    assert_not_nil workflow.uuid
  end

end
