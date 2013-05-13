require 'test_helper'
require 'time_test_helper'

class MailerTest < ActionMailer::TestCase
  fixtures :all

  test "signup" do
    @expected.subject = 'SEEK account activation'
    @expected.to = "Aaron Spiggle <aaron@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"

    @expected.body    = read_fixture('signup')
    

    assert_equal encode_mail(@expected), encode_mail(Mailer.signup(users(:aaron),"localhost"))
  end
  
  test "signup_open_id" do
    @expected.subject = 'SEEK account activation'
    @expected.to = "Aaron Openid Spiggle <aaron_openid@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"

    @expected.body    = read_fixture('signup_openid')

    assert_equal encode_mail(@expected), encode_mail(Mailer.signup(users(:aaron_openid),"localhost"))
    
  end
  
  test "announcement notification" do
    announcement = site_announcements(:mail)
    @expected.subject = "SEEK Announcement: #{announcement.title}"
    @expected.to = "Fred Blogs <fred@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"


    @expected.body    = read_fixture('announcement_notification')
    
    person=people(:fred)

    assert_equal encode_mail(@expected), encode_mail(Mailer.announcement_notification(announcement,person.notifiee_info,"localhost"))

  end

  test "feedback anonymously" do
    @expected.subject = 'SEEK Feedback provided - This is a test feedback'
    @expected.to = "Quentin Jones <quentin@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"    


    @expected.body    = read_fixture('feedback_anon')

    assert_equal encode_mail(@expected),encode_mail(Mailer.feedback(users(:aaron),"This is a test feedback","testing the feedback message",true,"localhost"))

  end

  test "feedback non anonymously" do
    @expected.subject = 'SEEK Feedback provided - This is a test feedback'
    @expected.to = "Quentin Jones <quentin@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"
    @expected.reply_to = "Aaron Spiggle <aaron@email.com>"

    @expected.body    = read_fixture('feedback_non_anon')

    assert_equal encode_mail(@expected),encode_mail(Mailer.feedback(users(:aaron),"This is a test feedback","testing the feedback message",false,"localhost"))

  end

  test "request resource" do
    @expected.subject = "A SEEK member requested a protected file: Picture"
    @expected.to = ["Datafile Owner <data_file_owner@email.com>","OwnerOf MyFirstSop <owner@sop.com>"]
    @expected.from = "no-reply@sysmo-db.org"
    @expected.reply_to = "Aaron Spiggle <aaron@email.com>"

    @expected.body = read_fixture('request_resource')

    resource=data_files(:picture)
    user=users(:aaron)
    details="here are some more details"

    assert_equal encode_mail(@expected),encode_mail(Mailer.request_resource(user,resource,details,"localhost"))

  end

  test "request resource no details" do
    @expected.subject = "A SEEK member requested a protected file: Picture"
    #TODO: hardcoding the formating rather than passing an array was require for rails 2.3.8 upgrade
    @expected.to = "Datafile Owner <data_file_owner@email.com>,\r\n\t OwnerOf MyFirstSop <owner@sop.com>"
    @expected.from = "no-reply@sysmo-db.org"
    @expected.reply_to = "Aaron Spiggle <aaron@email.com>"


    @expected.body = read_fixture('request_resource_no_details')

    resource=data_files(:picture)
    user=users(:aaron)
    details=""

    assert_equal encode_mail(@expected),encode_mail(Mailer.request_resource(user,resource,details,"localhost"))

  end

  test "request publish approval" do
    resource = data_files(:picture)
    gatekeeper = people(:gatekeeper_person)
    @expected.subject = "A SEEK member requested your approval to publish: #{resource.title}"

    @expected.to = gatekeeper.email_with_name
    @expected.from = "no-reply@sysmo-db.org"
    @expected.reply_to = "Aaron Spiggle <aaron@email.com>"


    @expected.body = read_fixture('request_publish_approval')
    user=users(:aaron)

    assert_equal encode_mail(@expected),encode_mail(Mailer.request_publish_approval([gatekeeper],user,resource,"localhost"))

  end

  test "request publishing" do

    @expected.subject = "A SEEK member requests you make some items public"
    @expected.to = "Datafile Owner <data_file_owner@email.com>"
    @expected.from = "no-reply@sysmo-db.org"
    @expected.reply_to = "Aaron Spiggle <aaron@email.com>"

    @expected.body = read_fixture('request_publishing')

    publisher = people(:aaron_person)
    owner = people(:person_for_datafile_owner)

    resources=[assays(:metabolomics_assay),data_files(:picture),models(:teusink),assays(:metabolomics_assay2),data_files(:sysmo_data_file)]

    assert_equal encode_mail(@expected),encode_mail(Mailer.request_publishing(publisher,owner,resources,"localhost"))

  end

  test "gatekeeper approval feedback" do
    resource = data_files(:picture)
    gatekeeper = people(:gatekeeper_person)
    requester = people(:aaron_person)
    @expected.subject = "A SEEK gatekeeper approved your request to publish: #{resource.title}"

    @expected.to = requester.email_with_name
    @expected.from = "no-reply@sysmo-db.org"


    @expected.body = read_fixture('gatekeeper_approval_feedback')


    assert_equal encode_mail(@expected),encode_mail(Mailer.gatekeeper_approval_feedback(requester, gatekeeper, resource,"localhost"))

  end

  test "gatekeeper reject feedback" do
    resource = data_files(:picture)
    gatekeeper = people(:gatekeeper_person)
    requester = people(:aaron_person)
    @expected.subject = "A SEEK gatekeeper rejected your request to publish: #{resource.title}"

    @expected.to = requester.email_with_name
    @expected.from = "no-reply@sysmo-db.org"
    @expected.reply_to = gatekeeper.email_with_name


    @expected.body = read_fixture('gatekeeper_reject_feedback')
    extra_comment = 'Not ready'

    assert_equal encode_mail(@expected),encode_mail(Mailer.gatekeeper_reject_feedback(requester, gatekeeper, resource, extra_comment, "localhost"))

  end


  test "forgot_password" do
    @expected.subject = 'SEEK - Password reset'
    @expected.to = "Aaron Spiggle <aaron@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"


    @expected.body    = read_fixture('forgot_password')
    
    u=users(:aaron)
    u.reset_password_code_until = 1.day.from_now
    u.reset_password_code="fred"
    

    assert_equal encode_mail(@expected), encode_mail(Mailer.forgot_password(users(:aaron),"localhost"))

  end

  test "contact_admin_new_user_no_profile" do
    @expected.subject = 'SEEK member signed up'
    @expected.to = "Quentin Jones <quentin@email.com>"
    @expected.from = "no-reply@sysmo-db.org"
    @expected.reply_to = "Aaron Spiggle <aaron@email.com>"

    @expected.body = read_fixture('contact_admin_new_user_no_profile')

    assert_equal encode_mail(@expected),
                 encode_mail(Mailer.contact_admin_new_user_no_profile("test message", users(:aaron), "localhost"))
  end

  test "contact_project_manager_new_user_no_profile" do
    project_manager = Factory(:project_manager)
    @expected.subject = 'SEEK member signed up, please assign this person to the projects which you are project manager'
    @expected.to = project_manager.email_with_name
    @expected.from = "no-reply@sysmo-db.org"
    @expected.reply_to = "Aaron Spiggle <aaron@email.com>"


    @expected.body = read_fixture('contact_project_manager_new_user_no_profile')

    assert_equal encode_mail(@expected),
                 encode_mail(Mailer.contact_project_manager_new_user_no_profile(project_manager, "test message", users(:aaron), "localhost"))


  end

  test "welcome" do
    @expected.subject = 'Welcome to SEEK'
    @expected.to = "Quentin Jones <quentin@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"
    
    @expected.body = read_fixture('welcome')

    assert_equal encode_mail(@expected), encode_mail(Mailer.welcome(users(:quentin),"localhost"))

  end

  private

  def encode_mail message
    message.encoded.gsub(/Message-ID: <.+>/, '').gsub(/Date: .+/, '')
  end


end
