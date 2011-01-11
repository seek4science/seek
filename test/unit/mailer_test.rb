require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../time_test_helper'

class MailerTest < ActionMailer::TestCase
  fixtures :all

  test "signup" do
    @expected.subject = 'Sysmo SEEK account activation'
    @expected.to = "Aaron Spiggle <aaron@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"
    @expected.date    = Time.now

    @expected.body    = read_fixture('signup')
    
    pretend_now_is(@expected.date) do
      assert_equal @expected.encoded, Mailer.create_signup(users(:aaron),"localhost").encoded
    end
    
  end
  
  test "signup_open_id" do
    @expected.subject = 'Sysmo SEEK account activation'
    @expected.to = "Aaron Openid Spiggle <aaron_openid@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"
    @expected.date    = Time.now

    @expected.body    = read_fixture('signup_openid')
    
    pretend_now_is(@expected.date) do
      assert_equal @expected.encoded, Mailer.create_signup(users(:aaron_openid),"localhost").encoded
    end
    
  end
  
  test "announcement notification" do
    announcement = site_announcements(:mail)
    @expected.subject = "Sysmo SEEK Announcement: #{announcement.title}"
    @expected.to = "Fred Blogs <fred@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"
    @expected.date    = Time.now

    @expected.body    = read_fixture('announcement_notification')
    
    person=people(:fred)
    pretend_now_is(@expected.date) do
      assert_equal @expected.encoded, Mailer.create_announcement_notification(announcement,person.notifiee_info,"localhost").encoded
    end    
  end

  test "feedback anonymously" do
    @expected.subject = 'Sysmo SEEK Feedback provided - This is a test feedback'
    @expected.to = "Quentin Jones <quentin@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"    
    @expected.date    = Time.now

    @expected.body    = read_fixture('feedback_anon')
    pretend_now_is(@expected.date) do
      assert_equal @expected.encoded,Mailer.create_feedback(users(:aaron),"This is a test feedback","testing the feedback message",true,"localhost").encoded
    end
  end

  test "feedback non anonymously" do
    @expected.subject = 'Sysmo SEEK Feedback provided - This is a test feedback'
    @expected.to = "Quentin Jones <quentin@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"
    @expected.reply_to = "Aaron Spiggle <aaron@email.com>"
    @expected.date    = Time.now

    @expected.body    = read_fixture('feedback_non_anon')
    pretend_now_is(@expected.date) do
      assert_equal @expected.encoded,Mailer.create_feedback(users(:aaron),"This is a test feedback","testing the feedback message",false,"localhost").encoded
    end
  end

  test "request resource" do
    @expected.subject = "A Sysmo SEEK member requested a protected file: Picture"
    @expected.to = ["Datafile Owner <data_file_owner@email.com>","OwnerOf MyFirstSop <owner@sop.com>"]
    @expected.from = "no-reply@sysmo-db.org"
    @expected.reply_to = "Aaron Spiggle <aaron@email.com>"
    @expected.date = Time.now

    @expected.body = read_fixture('request_resource')

    resource=data_files(:picture)
    user=users(:aaron)
    details="here are some more details"
    pretend_now_is(@expected.date) do
      assert_equal @expected.encoded,Mailer.create_request_resource(user,resource,details,"localhost").encoded
    end
  end

  test "request resource no details" do
    @expected.subject = "A Sysmo SEEK member requested a protected file: Picture"
    @expected.to = ["Datafile Owner <data_file_owner@email.com>","OwnerOf MyFirstSop <owner@sop.com>"]
    @expected.from = "no-reply@sysmo-db.org"
    @expected.reply_to = "Aaron Spiggle <aaron@email.com>"
    @expected.date = Time.now

    @expected.body = read_fixture('request_resource_no_details')

    resource=data_files(:picture)
    user=users(:aaron)
    details=""
    pretend_now_is(@expected.date) do
      assert_equal @expected.encoded,Mailer.create_request_resource(user,resource,details,"localhost").encoded
    end
  end

  test "forgot_password" do
    @expected.subject = 'Sysmo SEEK - Password reset'
    @expected.to = "Aaron Spiggle <aaron@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"
    @expected.date    = Time.now

    @expected.body    = read_fixture('forgot_password')
    
    u=users(:aaron)
    u.reset_password_code_until = 1.day.from_now
    u.reset_password_code="fred"
    
    pretend_now_is(@expected.date) do
      assert_equal @expected.encoded, Mailer.create_forgot_password(users(:aaron),"localhost").encoded
    end    
  end

  test "contact_admin_new_user_no_profile" do
    @expected.subject = 'Sysmo SEEK member signed up'
    @expected.to = "Quentin Jones <quentin@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"
    @expected.reply_to = "Aaron Spiggle <aaron@email.com>"
    @expected.date    = Time.now

    @expected.body    = read_fixture('contact_admin_new_user_no_profile')
    
    pretend_now_is(@expected.date) do
      assert_equal @expected.encoded, 
        Mailer.create_contact_admin_new_user_no_profile("test message",users(:aaron),"localhost").encoded
    end
    
  end

  test "welcome" do
    @expected.subject = 'Welcome to Sysmo SEEK'
    @expected.to = "Quentin Jones <quentin@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"
    @expected.date = Time.now
    
    @expected.body = read_fixture('welcome')
    
    pretend_now_is(@expected.date) do
      assert_equal @expected.encoded, Mailer.create_welcome(users(:quentin),"localhost").encoded
    end
  end

end
