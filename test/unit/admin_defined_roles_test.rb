require 'test_helper'

class AdminDefinedRolesTest < ActiveSupport::TestCase

  test 'assign admin role for a person' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      assert_equal [], person.roles
      assert person.can_manage?
      person.roles=['admin']
      person.save!
      person.reload
      assert_equal ['admin'], person.roles
    end
  end

  test 'add roles for a person' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:admin)
      assert_equal ['admin'], person.roles
      assert person.can_manage?
      person.add_roles ['admin', 'pal']
      person.save!
      person.reload
      assert_equal ['admin', 'pal'].sort, person.roles.sort
    end
  end

  test 'remove roles for a person' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      person.roles = ['admin', 'pal']
      person.remove_roles ['admin']
      person.save!
      person.reload
      assert_equal ['pal'], person.roles
    end
  end

  test 'non-admin can not change the roles of a person' do
    person = Factory(:person)
    User.with_current_user person.user do

      person.roles = ['admin', 'pal']
      assert person.can_edit?
      assert !person.save
      assert !person.errors.empty?
      person.reload
      assert_equal [], person.roles
    end
  end

  test 'is_admin?' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      person.is_admin = true
      person.save!

      assert person.is_admin?

      person.is_admin = false
      person.save!

      assert !person.is_admin?
    end
  end

  test 'is_pal?' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      person.is_pal = true
      person.save!

      assert person.is_pal?

      person.is_pal = false
      person.save!

      assert !person.is_pal?
    end
  end

  test 'is_project_manager?' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      person.is_project_manager= true
      person.save!

      assert person.is_project_manager?

      person.is_project_manager=false
      person.save!

      assert !person.is_project_manager?
    end
  end

  test 'is_gatekeeper?' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      person.is_gatekeeper= true
      person.save!

      assert person.is_gatekeeper?

      person.is_gatekeeper=false
      person.save!

      assert !person.is_gatekeeper?
    end
  end

  test 'is_asset_manager?' do
    User.with_current_user Factory(:admin).user do
      person = Factory(:person)
      person.is_asset_manager = true
      person.save!

      assert person.is_asset_manager?

      person.is_asset_manager=false
      person.save!

      assert !person.is_asset_manager?
    end
  end

  test 'is_asset_manager_of?' do
    asset_manager = Factory(:asset_manager)
    sop = Factory(:sop)
    assert !asset_manager.is_asset_manager_of?(sop)

    disable_authorization_checks{sop.projects = asset_manager.projects}
    assert asset_manager.is_asset_manager_of?(sop)
  end

  test 'is_gatekeeper_of?' do
    gatekeeper = Factory(:gatekeeper)
    sop = Factory(:sop)
    assert !gatekeeper.is_gatekeeper_of?(sop)

    disable_authorization_checks{sop.projects = gatekeeper.projects}
    assert gatekeeper.is_gatekeeper_of?(sop)
  end

  test "order of ROLES" do
    assert_equal %w[admin pal project_manager asset_manager gatekeeper],Person::ROLES,"The order of the ROLES is critical as it determines the mask that is used."
  end

  test 'replace admins, pals named_scope by a static function' do

    normal = Factory(:person)
    admin = Factory(:admin)
    pal = Factory(:pal)

    admins = Person.admins

    assert admins.include?(admin)
    assert !admins.include?(normal)
    assert !admins.include?(pal)

    pals = Person.pals

    assert pals.include?(pal)
    assert !pals.include?(admin)
    assert !pals.include?(normal)
  end
end