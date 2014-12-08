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
    announcement = Factory(:mail_announcement)
    recipient = Factory(:person)

    @expected.subject = "SEEK Announcement: #{announcement.title}"
    @expected.to = recipient.email_with_name
    @expected.from    = "no-reply@sysmo-db.org"


    @expected.body    = read_fixture('announcement_notification')
    expected_text = encode_mail(@expected)
    expected_text.gsub!("-unique_key-",recipient.notifiee_info.unique_key)

    assert_equal expected_text, encode_mail(Mailer.announcement_notification(announcement,recipient.notifiee_info,"localhost"))

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
    gatekeeper = Factory(:gatekeeper,:first_name=>"Gatekeeper",:last_name=>"Last")
    resources = [Factory(:data_file,:projects=>gatekeeper.projects,:title=>"Picture"),Factory(:teusink_model,:projects=>gatekeeper.projects,:title=>"Teusink")]
    requester=Factory(:person,:first_name=>"Aaron",:last_name=>"Spiggle").user

    @expected.subject = "A SEEK member requested your approval to publish some items."

    @expected.to = gatekeeper.email_with_name
    @expected.from = "no-reply@sysmo-db.org"
    @expected.reply_to = requester.person.email_with_name


    @expected.body = read_fixture('request_publish_approval')


    expected_text = encode_mail(@expected)
    expected_text.gsub!("-person_id-",gatekeeper.id.to_s)
    expected_text.gsub!("-df_id-",resources[0].id.to_s)
    expected_text.gsub!("-model_id-",resources[1].id.to_s)
    expected_text.gsub!("-requester_id-",requester.person.id.to_s)

    assert_equal expected_text,encode_mail(Mailer.request_publish_approval(gatekeeper,requester,resources,"localhost"))

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
    gatekeeper = Factory(:gatekeeper,:first_name=>"Gatekeeper",:last_name=>"Last")
    item = Factory(:data_file,:projects=>gatekeeper.projects,:title=>"Picture")
    items_and_comments = [{:item => item, :comment => nil}]
    requester = Factory(:person,:first_name=>"Aaron",:last_name=>"Spiggle")
    @expected.subject = "A SEEK gatekeeper approved your publishing requests."

    @expected.to = requester.email_with_name
    @expected.from = "no-reply@sysmo-db.org"


    @expected.body = read_fixture('gatekeeper_approval_feedback')
    expected_text = encode_mail(@expected)
    expected_text.gsub!("-person_id-",gatekeeper.id.to_s)
    expected_text.gsub!("-df_id-",item.id.to_s)

    assert_equal expected_text,encode_mail(Mailer.gatekeeper_approval_feedback(requester, gatekeeper, items_and_comments,"localhost"))

  end

  test "gatekeeper reject feedback" do
    gatekeeper = Factory(:gatekeeper,:first_name=>"Gatekeeper",:last_name=>"Last")
    item = Factory(:data_file,:projects=>gatekeeper.projects,:title=>"Picture")
    items_and_comments = [{:item => item, :comment => 'not ready'}]

    requester = Factory(:person,:first_name=>"Aaron",:last_name=>"Spiggle")
    @expected.subject = "A SEEK gatekeeper rejected your publishing requests."

    @expected.to = requester.email_with_name
    @expected.from = "no-reply@sysmo-db.org"
    @expected.reply_to = gatekeeper.email_with_name


    @expected.body = read_fixture('gatekeeper_reject_feedback')

    expected_text = encode_mail(@expected)
    expected_text.gsub!("-person_id-",gatekeeper.id.to_s)
    expected_text.gsub!("-df_id-",item.id.to_s)

    assert_equal expected_text,encode_mail(Mailer.gatekeeper_reject_feedback(requester, gatekeeper, items_and_comments, "localhost"))
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

  test "contact_admin_new_user" do
    @expected.subject = 'SEEK member signed up'
    @expected.to =  "Quentin Jones <quentin@email.com>"
    @expected.from = "no-reply@sysmo-db.org"
    @expected.reply_to = "Aaron Spiggle <aaron@email.com>"

    @expected.body = read_fixture('contact_admin_new_user')

    assert_equal encode_mail(@expected),
                 encode_mail(Mailer.contact_admin_new_user("test message", users(:aaron), "localhost"))
  end

  test "contact_project_manager_new_user" do
    project_manager = Factory(:project_manager)
    @expected.subject = 'SEEK member signed up, please assign this person to the projects of which you are project manager'
    @expected.to = project_manager.email_with_name
    @expected.from = "no-reply@sysmo-db.org"
    @expected.reply_to = "Aaron Spiggle <aaron@email.com>"


    @expected.body = read_fixture('contact_project_manager_new_user')

    assert_equal encode_mail(@expected),
                 encode_mail(Mailer.contact_project_manager_new_user(project_manager, "test message", users(:aaron), "localhost"))


  end

  test "welcome" do
    @expected.subject = 'Welcome to SEEK'
    @expected.to = "Quentin Jones <quentin@email.com>"
    @expected.from    = "no-reply@sysmo-db.org"
    
    @expected.body = read_fixture('welcome')

    assert_equal encode_mail(@expected), encode_mail(Mailer.welcome(users(:quentin),"localhost"))

  end

  test "test mail" do
    with_config_value(:application_title,"SEEK EMAIL TEST") do
      with_config_value(:site_base_host,"http://fred.com") do
        email = Mailer.test_email("fred@email.com")
        assert_not_nil email
        assert_equal  "SEEK Configuration Email Test",email.subject
        assert_equal ["no-reply@sysmo-db.org"],email.from
        assert_equal ["fred@email.com"],email.to

        assert email.body.include?("This is a test email sent from SEEK EMAIL TEST configured with the Site base URL of http://fred.com")
      end
    end

  end

  private

  def encode_mail message
    message.encoded.gsub(/Message-ID: <.+>/, '').gsub(/Date: .+/, '')
  end


end
