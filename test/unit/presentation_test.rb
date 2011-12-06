require "test_helper"

class PresentationTest < ActiveSupport::TestCase

 test "validations" do
   presentation = Factory :presentation
   presentation.title=""

   assert !presentation.valid?

   presentation.reload
   presentation.projects.clear
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

    old_attrs.delete("version")
    new_attrs = presentation.attributes
    new_attrs.delete("version")

    old_attrs.delete("updated_at")
    new_attrs.delete("updated_at")

    old_attrs.delete("created_at")
    new_attrs.delete("created_at")

    assert_equal old_attrs,new_attrs
  end

  test "event association" do
    presentation = Factory :presentation
    assert presentation.events.empty?

    User.current_user = presentation.contributor
    assert_difference "presentation.events.count" do
         presentation.events << Factory(:event)
    end

  end

  test "has uuid" do
    presentation = Factory :presentation
    assert_not_nil presentation.uuid
  end




end