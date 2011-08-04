require "test_helper"

class PresentationTest < ActiveSupport::TestCase

 test "validations" do
   presentation = Factory :presentation
   presentation.title=""

   assert !presentation.valid?

   presentation.reload
   presentation.project = nil
   assert !presentation.valid?
 end

  test "default_policy_is_private" do
    presentation = Factory :presentation
    assert_not_nil presentation.policy

    assert_equal presentation.policy.sharing_scope , Policy::PRIVATE
    assert_equal presentation.policy.access_type , Policy::NO_ACCESS
    assert_equal false, presentation.policy.use_whitelist
    assert_equal false, presentation.policy.use_blacklist
    assert presentation.policy.permissions.empty?
  end

  test "new presentation's version is 1" do
    presentation = Factory :presentation
    assert_equal 1,presentation.version
  end

  test "can create new version of presentation" do
    presentation = Factory :presentation
    old_attrs = presentation.attributes

    presentation.save_as_new_version("new version")

    assert_equal 1,old_attrs["version"]
    assert_equal 2, presentation.version

    old_other_attrs = old_attrs.select{|k,v|k!="version"}
    new_other_attrs = presentation.attributes.select{|k,v|k!="version"}

    assert_equal old_other_attrs,new_other_attrs
  end

  test "event association" do
    presentation = Factory :presentation
    assert presentation.events.empty?

    User.current_user = presentation.contributor
    assert_difference "presentation.events.count" do
         presentation.events << Factory(:event)
    end

  end




end