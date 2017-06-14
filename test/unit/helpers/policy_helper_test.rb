require 'test_helper'

class PolicyHelperTest < ActionView::TestCase
  test 'policy selection options accessible removed if not downloadable' do
    policies = [Policy::NO_ACCESS, Policy::VISIBLE, Policy::ACCESSIBLE, Policy::EDITING]
    resource = nil # not downloadable
    selected_access_type = Policy::NO_ACCESS
    actual_options = policy_selection_options policies, resource, selected_access_type

    expected_options = "<option selected=\"selected\" value=\"0\">No access</option>\n<option value=\"1\">View summary</option>\n<option value=\"3\">View and edit summary</option>"

    assert_equal expected_options, actual_options
  end

  #  handle access_type = ACCESSIBLE, and !resource.is_downloadable?
  #  Seek::Config.default :default_projects_access_type = @resource.is_asset? ? Policy::ACCESSIBLE : Policy::VISIBLE
  test 'policy selection options handles access type accessible selected but item not downloadable' do
    policies = [Policy::NO_ACCESS, Policy::VISIBLE, Policy::ACCESSIBLE, Policy::EDITING]
    resource = nil # not downloadable
    selected_access_type = Policy::ACCESSIBLE
    actual_options = policy_selection_options policies, resource, selected_access_type

    expected_options = "<option value=\"0\">No access</option>\n<option selected=\"selected\" value=\"1\">View summary</option>\n<option value=\"3\">View and edit summary</option>"

    assert_equal expected_options, actual_options, "default selected access type should change from accessible
to visible if item is not downloadable and the accessible option is removed."
  end

  test 'policy selection options keeps access type accessible selected when item is downloadable' do
    policies = [Policy::NO_ACCESS, Policy::VISIBLE, Policy::ACCESSIBLE, Policy::EDITING]
    resource = DataFile.new # is downloadable
    selected_access_type = Policy::ACCESSIBLE
    actual_options = policy_selection_options policies, resource, selected_access_type

    expected_options = "<option value=\"0\">No access</option>\n<option value=\"1\">View summary only</option>\n<option selected=\"selected\" value=\"2\">View summary and get contents</option>\n<option value=\"3\">View and edit summary and contents</option>"

    assert_equal expected_options, actual_options, "default selected access type should change from accessible
to visible if item is not downloadable and the accessible option is removed."
  end
end
