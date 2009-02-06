require 'test_helper'

class MailerTest < ActionMailer::TestCase
  test "signup" do
    @expected.subject = 'Mailer#signup'
    @expected.body    = read_fixture('signup')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Mailer.create_signup(@expected.date).encoded
  end

  test "forgot_password" do
    @expected.subject = 'Mailer#forgot_password'
    @expected.body    = read_fixture('forgot_password')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Mailer.create_forgot_password(@expected.date).encoded
  end

  test "contact_admin" do
    @expected.subject = 'Mailer#contact_admin'
    @expected.body    = read_fixture('contact_admin')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Mailer.create_contact_admin(@expected.date).encoded
  end

end
