require 'test_helper'

class MailerTest < ActionMailer::TestCase
  fixtures :users, :people

  test "signup" do
    @expected.subject = 'Sysmo SEEK account activation'
    @expected.to = "Aaron Spiggle <aaron@email.com>"
    @expected.body    = read_fixture('signup')
    @expected.date    = Time.now
    @expected.from    = "no-reply@sysmo-db.org"

    assert_equal @expected.encoded, Mailer.create_signup(users(:aaron),"localhost").encoded
  end

  test "forgot_password" do
    @expected.subject = 'Sysmo SEEK - Password reset'
    @expected.to = "Aaron Spiggle <aaron@email.com>"
    @expected.body    = read_fixture('forgot_password')
    @expected.date    = Time.now
    @expected.from    = "no-reply@sysmo-db.org"

    u=users(:aaron)
    u.reset_password_code_until = 1.day.from_now
    u.reset_password_code="fred"
    assert_equal @expected.encoded, Mailer.create_forgot_password(users(:aaron),"localhost").encoded
  end

  test "contact_admin_new_user_no_profile" do
    @expected.subject = 'Sysmo Member signed up'
    @expected.body    = read_fixture('contact_admin_new_user_no_profile')
    @expected.date    = Time.now
    @expected.to = "Quentin Jones <quentin@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"

    assert_equal @expected.encoded, 
      Mailer.create_contact_admin_new_user_no_profile("test message",users(:quentin),"localhost").encoded
  end

  test "welcome" do
    @expected.subject = 'Welcome to Sysmo SEEK'
    @expected.body = read_fixture('welcome')
    @expected.date = Time.now
    @expected.to = "Quentin Jones <quentin@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"

    assert_equal @expected.encoded, Mailer.create_welcome(users(:quentin),"localhost").encoded
  end

end
