require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead.
  # Then, you can remove it from this and the functional test.
  
  include AuthenticatedTestHelper
  fixtures :users,:sops,:data_files,:models,:assets

  def test_without_profile
    without_profile=User.without_profile
    without_profile.each do |u|
      assert u.person.nil?
    end
    assert without_profile.include?(users(:part_registered))
    assert !without_profile.include?(users(:aaron))

    aaron=users(:aaron)
    aaron.person=nil
    aaron.save!

    without_profile=User.without_profile
    without_profile.each do |u|
      assert u.person.nil?
    end
    assert without_profile.include?(users(:part_registered))
    assert without_profile.include?(users(:aaron))
  end

  test "project manager logged in?" do
    pm = Factory :project_manager
    normal = Factory :person
    User.with_current_user(pm.user) do
      assert User.project_manager_logged_in?
    end

    User.with_current_user(normal.user) do
      assert !User.project_manager_logged_in?
    end
  end

  def test_activate
    user = Factory :brand_new_user

    assert !user.active?

    user.activate
    user.reload
    assert user.active?
  end

  def test_not_activated
    not_activated=User.not_activated
    not_activated.each do |u|
      assert !u.active?
    end
    assert not_activated.include?(users(:aaron))
    assert !not_activated.include?(users(:quentin))
  end

  def test_should_create_user
    assert_difference 'User.count' do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end

  def test_should_initialize_activation_code_upon_creation
    user = create_user
    user.reload
    assert_not_nil user.activation_code
  end

  def test_should_require_login
    assert_no_difference 'User.count' do
      u = create_user(:login => nil)
      assert u.errors.get(:login)
    end
  end

  def test_should_require_password
    assert_no_difference 'User.count' do
      u = create_user(:password => nil)
      assert u.errors.get(:password)
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference 'User.count' do
      u = create_user(:password_confirmation => nil)
      assert u.errors.get(:password_confirmation)
    end
  end

  def test_should_not_require_email
    assert_difference 'User.count' do
      u = create_user(:email => nil)
    end
  end

  def test_should_reset_password
    users(:quentin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:quentin), User.authenticate('quentin', 'new password')
  end

  def test_should_not_rehash_password
    users(:quentin).update_attributes(:login => 'quentin2')
    assert_equal users(:quentin), User.authenticate('quentin2', 'test')
  end

  def test_should_authenticate_user
    assert_equal users(:quentin), User.authenticate('quentin', 'test')
  end

  def test_should_set_remember_token
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
  end

  def test_should_unset_remember_token
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    users(:quentin).forget_me
    assert_nil users(:quentin).remember_token
  end

  def test_should_remember_me_for_one_week
    before = 1.week.from_now.utc
    users(:quentin).remember_me_for 1.week
    after = 1.week.from_now.utc
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert users(:quentin).remember_token_expires_at.between?(before, after)
  end

  def test_should_remember_me_until_one_week
    time = 1.week.from_now.utc
    users(:quentin).remember_me_until time
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert_equal users(:quentin).remember_token_expires_at, time
  end

  def test_should_remember_me_default_two_weeks
    before = 2.weeks.from_now.utc
    users(:quentin).remember_me
    after = 2.weeks.from_now.utc
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert users(:quentin).remember_token_expires_at.between?(before, after)
  end

  def test_get_assets
    user=users(:owner_of_my_first_sop)
    assert user.sops.size>0
    assert user.sops.include?(sops(:my_first_sop))
    assert !user.sops.include?(sops(:sop_with_fully_public_policy))

    user=users(:model_owner)
    assert user.models.size>0
    assert user.models.include?(models(:teusink))
    assert !user.models.include?(models(:model_with_different_owner))

    user=users(:datafile_owner)
    assert user.data_files.size>0
    assert user.data_files.include?(data_files(:picture))
    assert !user.data_files.include?(data_files(:sysmo_data_file))

  end

  test "test uuid generated" do
    user = users(:aaron)
    assert_nil user.attributes["uuid"]
    user.save
    assert_not_nil user.attributes["uuid"]
  end
  
  test "uuid doesn't change" do
    x = users(:aaron)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end

  test 'test show_guide_box' do
    x = users(:aaron)
    assert x.show_guide_box?
    x.show_guide_box = false
    x.save
    x.reload
    assert !x.show_guide_box?
  end

protected
  def create_user(options = {})
    record = User.new({ :login => 'quire', :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire' }.merge(options))
    record.save
    record
  end
end
