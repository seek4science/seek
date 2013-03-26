require 'test_helper'

class PublishingPermissionsTest < ActiveSupport::TestCase
  test "is_published?" do
    User.with_current_user Factory(:user) do
      public_sop=Factory(:sop,:policy=>Factory(:public_policy,:access_type=>Policy::ACCESSIBLE))
      not_public_model=Factory(:model,:policy=>Factory(:public_policy, :access_type=>Policy::VISIBLE))
      public_datafile=Factory(:data_file,:policy=>Factory(:public_policy))
      public_assay=Factory(:assay,:policy=>Factory(:public_policy, :access_type=>Policy::VISIBLE))
      not_public_sample=Factory(:sample,:policy=>Factory(:all_sysmo_viewable_policy))

      assert public_sop.is_published?
      assert !not_public_model.is_published?
      assert public_datafile.is_published?
      assert public_assay.is_published?
      assert !not_public_sample.is_published?
    end
  end

  test "publish" do
    user = Factory(:user)
    private_model=Factory(:model,:contributor=>user,:policy=>Factory(:public_policy,:access_type=>Policy::VISIBLE))
    User.with_current_user user do
      assert private_model.can_manage?,"Should be able to manage this model for the test to work"
      assert private_model.publish!
    end
    private_model.reload
    assert_equal Policy::ACCESSIBLE,private_model.policy.access_type
    assert_equal Policy::EVERYONE,private_model.policy.sharing_scope

  end

  test "is_in_isa_publishable?" do
    assert Factory(:sop).is_in_isa_publishable?
    assert Factory(:model).is_in_isa_publishable?
    assert Factory(:data_file).is_in_isa_publishable?
    assert !Factory(:assay).is_in_isa_publishable?
    assert !Factory(:investigation).is_in_isa_publishable?
    assert !Factory(:study).is_in_isa_publishable?
    assert !Factory(:event).is_in_isa_publishable?
    assert !Factory(:publication).is_in_isa_publishable?
  end

  test "can_send_publishing_request?" do
    assay = Factory(:assay)
    user = assay.owner.user

    #can_send_publishing_request? if there is gatekeeper and can_manage? and the publishing request has not been sent
    gatekeeper = Factory(:gatekeeper)
    assay.projects << gatekeeper.projects.first
    assert assay.save

    assert !assay.can_publish?(user)
    assert assay.can_manage?(user)
    assert ResourcePublishLog.last_waiting_approval_log(assay,user).nil?
    assert assay.can_send_publishing_request?(user)

    #not can_send_publishing_request? if there is gatekeeper and can_manage? and the publishing request was sent
    ResourcePublishLog.add_publish_log(ResourcePublishLog::WAITING_FOR_APPROVAL,assay,user)
    assert !ResourcePublishLog.last_waiting_approval_log(assay,user).nil?
    assert !assay.can_send_publishing_request?(user)

    #not can_send_publishing_request? if can not manage
    other_user = Factory(:user)
    assert !assay.can_manage?(other_user)
    assert !assay.can_send_publishing_request?(other_user)
  end
end