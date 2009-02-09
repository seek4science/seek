require 'test_helper'

class MailerTest < ActionMailer::TestCase
  fixtures :users, :people

  test "signup" do
    @expected.subject = 'Sysmo SEEK account activation'
    @expected.to = "Aaron Spiggle <aaron@email.com>"
    @expected.body    = read_fixture('signup')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Mailer.create_signup(users(:aaron),"http://localhost").encoded
  end

  test "forgot_password" do
    @expected.subject = 'Mailer#forgot_password'
    @expected.body    = read_fixture('forgot_password')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Mailer.create_forgot_password(@expected.date).encoded
  end

  test "contact_admin_new_user_no_profile" do
    @expected.subject = 'Mailer#contact_admin'
    @expected.body    = read_fixture('contact_admin_new_user_no_profile')
    @expected.date    = Time.now

    #FIXME: commented out test while works in progress
    #assert_equal @expected.encoded, Mailer.create_contact_admin_new_user_no_profile("test message",people(:one)).encoded
  end

end
