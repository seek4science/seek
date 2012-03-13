require 'test_helper'

class PolicyBasedAuthTest < ActiveSupport::TestCase
  test "has advanced permissions" do
    user = Factory(:user)
    User.current_user = user
    proj1=Factory :project
    proj2=Factory :project
    person1 = Factory :person
    person2 = Factory :person
    df = Factory :data_file, :policy => Factory(:private_policy), :contributor => user.person,:projects=>[proj1]

    assert !df.has_advanced_permissions?
    df.policy.permissions << Factory(:permission,:contributor=>person1,:access_type=>Policy::EDITING)
    df.save!
    assert df.has_advanced_permissions?

    model = Factory :model,:policy=>Factory(:public_policy),:contributor=>user.person,:projects=>[proj1,proj2]
    assert !model.has_advanced_permissions?
    model.policy.permissions << Factory(:permission,:contributor=>Factory(:institution),:access_type=>Policy::ACCESSIBLE)
    model.save!
    assert model.has_advanced_permissions?

    #when having a sharing_scope policy of Policy::ALL_SYSMO_USERS it is concidered to have advanced permissions if any of the permissions do not relate to the projects associated with the resource (ISA or Asset))
    #this is a temporary work-around for the loss of the custom_permissions flag when defining a pre-canned permission of shared with sysmo, but editable/downloadable within mhy project
    assay = Factory :experimental_assay,:policy=>Factory(:all_sysmo_viewable_policy),:contributor=>user.person,:study=>Factory(:study, :investigation=>Factory(:investigation,:projects=>[proj1,proj2]))
    assay.policy.permissions << Factory(:permission,:contributor=>proj1,:access_type=>Policy::EDITING)
    assay.policy.permissions << Factory(:permission,:contributor=>proj2,:access_type=>Policy::EDITING)
    assay.save!
    assert !assay.has_advanced_permissions?
    proj_permission = Factory(:permission,:contributor=>Factory(:project),:access_type=>Policy::EDITING)
    assay.policy.permissions << proj_permission
    assert assay.has_advanced_permissions?
    assay.policy.permissions.delete(proj_permission)
    assay.save!
    assert !assay.has_advanced_permissions?
    assay.policy.permissions << Factory(:permission,:contributor=>Factory(:project),:access_type=>Policy::VISIBLE)
    assert assay.has_advanced_permissions?
  end

  test "should cache" do

  end

end