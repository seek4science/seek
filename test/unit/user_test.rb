require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead.
  # Then, you can remove it from this and the functional test.

  include AuthenticatedTestHelper
  fixtures :users, :sops, :data_files, :models, :assets

  test 'validates email if set' do
    u = FactoryBot.create :user
    assert u.valid?

    u.email = 'fish'
    refute u.valid?

    u.email = 'http://fish.com'
    refute u.valid?

    u.email = 'fish@example.com'
    assert u.valid?
  end

  test 'registration_compelete?' do
    u = FactoryBot.create :brand_new_user
    refute u.person
    refute u.registration_complete?

    # its not complete until the association has been saved
    u.person = FactoryBot.build(:brand_new_person)
    assert u.person
    refute u.registration_complete?

    u = FactoryBot.create :user
    assert u.person
    assert u.registration_complete?
  end

  test 'check email present?' do
    u = FactoryBot.create :user
    assert u.email.nil?
    assert u.valid?

    u.check_email_present = true
    refute u.valid?
    u.email = ''
    refute u.valid?
    u.email = 'fish@example.com'
    assert u.valid?
  end

  test 'check email available' do
    # email must not belong to another person, unless that person is unregistered
    u = FactoryBot.create :user
    u.check_email_present = true
    u.email = 'ghghgh@email.com'
    assert u.valid?
    FactoryBot.create(:person, email: 'ghghgh@email.com')

    refute u.valid?

    FactoryBot.create(:brand_new_person, email: 'zzzzzz@email.com')
    u.email = 'zzzzzz@email.com'
    assert u.valid?
  end

  test 'validation of login' do
    u = FactoryBot.create :user
    assert u.valid?
    u.login = nil
    refute u.valid?
    u.login = ''
    refute u.valid?
    u.login = 'aa'
    refute u.valid?
    u.login = 'aaa'
    assert u.valid?
    u.login = 'z' * 120
    assert u.valid?
    u.login = 'z' * 121
    refute u.valid?
  end

  def test_without_profile
    user_with_profile = FactoryBot.create(:user)
    user_without_profile = FactoryBot.create(:brand_new_user)

    assert_nil user_without_profile.person
    refute_nil user_with_profile.person

    without_profile = User.without_profile
    without_profile.each do |u|
      assert u.person.nil?
    end
    assert without_profile.include?(user_without_profile)
    assert !without_profile.include?(user_with_profile)

    user_with_profile.person = nil
    user_with_profile.save!

    without_profile = User.without_profile
    without_profile.each do |u|
      assert u.person.nil?
    end
    assert without_profile.include?(user_without_profile)
    assert without_profile.include? user_with_profile
  end

  test 'logged in and registered' do
    user = FactoryBot.create(:brand_new_user)
    User.with_current_user(user) do
      refute User.logged_in_and_registered?
    end
    user.person = Person.new
    User.with_current_user(user) do
      refute User.logged_in_and_registered?
    end
    user = FactoryBot.create(:person).user
    User.with_current_user(user) do
      assert User.logged_in_and_registered?
    end
  end

  test 'project administrator logged in?' do
    project_administrator = FactoryBot.create :project_administrator
    normal = FactoryBot.create :person
    User.with_current_user(project_administrator.user) do
      assert User.project_administrator_logged_in?
    end

    User.with_current_user(normal.user) do
      refute User.project_administrator_logged_in?
    end
  end

  test 'programme administrator logged in?' do
    programme_administrator = FactoryBot.create :programme_administrator
    normal = FactoryBot.create :person
    User.with_current_user(programme_administrator.user) do
      assert User.programme_administrator_logged_in?
    end

    User.with_current_user(normal.user) do
      refute User.programme_administrator_logged_in?
    end

    User.with_current_user(nil) do
      refute User.programme_administrator_logged_in?
    end
  end

  test 'activated_programme_administrator_logged_in? only if activated' do
    refute User.activated_programme_administrator_logged_in?
    person = FactoryBot.create(:programme_administrator)
    programme = person.administered_programmes.first

    # check programme is activated an is the only administered programme
    assert person.administered_programmes.first.is_activated?
    assert_equal [programme], person.administered_programmes

    User.with_current_user person.user do
      assert User.activated_programme_administrator_logged_in?
    end

    # not true unless the programme is activated
    programme.is_activated = false
    disable_authorization_checks { programme.save! }
    User.with_current_user person.user do
      refute User.activated_programme_administrator_logged_in?
    end
  end

  def test_activate
    user = FactoryBot.create :brand_new_user

    assert !user.active?

    user.activate
    user.reload
    assert user.active?
  end

  def test_not_activated
    no_person = FactoryBot.create(:brand_new_user)
    assert_nil no_person.person
    refute no_person.active?

    activated_with_person = FactoryBot.create(:user)
    refute_nil activated_with_person.person
    assert activated_with_person.active?

    valid_not_activated = FactoryBot.create(:brand_new_user,person:FactoryBot.create(:person))
    refute_nil valid_not_activated.person
    refute valid_not_activated.active?

    results = User.not_activated
    assert_includes results,valid_not_activated
    refute_includes results, no_person
    refute_includes results, activated_with_person

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
      u = create_user(login: nil)
      assert u.errors[:login]
    end
  end

  def test_should_require_password
    assert_no_difference 'User.count' do
      u = create_user(password: nil)
      assert u.errors[:password]
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference 'User.count' do
      u = create_user(password_confirmation: nil)
      assert u.errors[:password_confirmation]
    end
  end

  def test_should_reset_password
    users(:quentin).update(password: 'new password', password_confirmation: 'new password')
    assert_equal users(:quentin), User.authenticate('quentin', 'new password')
  end

  def test_should_not_rehash_password
    users(:quentin).update(login: 'quentin2')
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
    before = 1.week.from_now.utc - 1.second
    users(:quentin).remember_me_for 1.week
    after = 1.week.from_now.utc + 1.second
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert users(:quentin).remember_token_expires_at.between?(before, after)
  end

  def test_should_remember_me_until_one_week
    time = 1.week.from_now.utc
    users(:quentin).remember_me_until time
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert_equal users(:quentin).remember_token_expires_at.to_date, time.to_date
  end

  def test_should_remember_me_default_six_months
    before = 6.months.from_now.utc - 1.second
    users(:quentin).remember_me
    after = 6.months.from_now.utc + 1.second
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
    assert users(:quentin).remember_token_expires_at.between?(before, after)
  end

  test 'test uuid generated' do
    user = users(:aaron)
    assert_nil user.attributes['uuid']
    user.save
    assert_not_nil user.attributes['uuid']
  end

  test "uuid doesn't change" do
    x = users(:aaron)
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end

  test 'reset password' do
    user = FactoryBot.create(:user)
    assert_nil user.reset_password_code
    assert_nil user.reset_password_code_until
    user.reset_password
    refute_nil user.reset_password_code
    refute_nil user.reset_password_code_until
  end

  test 'password length' do
    assert_equal 10,User::MIN_PASSWORD_LENGTH
    user = FactoryBot.create(:user,password:'1234567890',password_confirmation:'1234567890')
    assert user.valid?
    user.password='123456789'
    user.password_confirmation='123456789'
    refute user.valid?

    user.password='123456789A'
    user.password_confirmation='123456789A'
    assert user.valid?
  end

  test 'fetch correct user' do
    alice = FactoryBot.create(:person, user: FactoryBot.create(:activated_user, login: 'alice'), email: 'alice@example.com')
    eve = FactoryBot.create(:person, user: FactoryBot.create(:activated_user, login: 'alice@example.com'), email: 'eve@example.com')

    assert_equal alice.user, User.get_user('alice')
    assert_equal alice.user, User.get_user('alice@example.com')
    assert_equal eve.user, User.get_user('eve@example.com')
  end

  test 'generate unique login' do
    FactoryBot.create(:user, login: 'alice')

    3.times do
      assert_match /alice[0-9]{4}/, User.unique_login('alice')
    end

    assert_nil User.find_by_login('this_login_is_already_unique')
    assert_equal 'this_login_is_already_unique', User.unique_login('this_login_is_already_unique')
  end

  protected

  def create_user(options = {})
    test_password = generate_user_password
    record = User.new({ login: 'quire', password: test_password, password_confirmation: test_password }.merge(options))
    record.save
    record
  end
end
