require 'test_helper'

class MailerTest < ActionMailer::TestCase
  fixtures :all

  def setup
    disable_authorization_checks { Person.where('first_name = ?', 'default admin').destroy_all }
  end

  test 'activation_request' do
    @expected.subject = 'Sysmo SEEK account activation'
    @expected.to = 'Aaron Spiggle <aaron@email.com>'
    @expected.from    = 'no-reply@sysmo-db.org'

    @expected.body    = read_fixture('activation_request')

    assert_equal encode_mail(@expected), encode_mail(Mailer.activation_request(users(:aaron)))
  end

  test 'announcement notification' do
    announcement = Factory(:mail_announcement)
    recipient = Factory(:person)

    @expected.subject = "Sysmo SEEK Announcement: #{announcement.title}"
    @expected.to = recipient.email_with_name
    @expected.from    = 'no-reply@sysmo-db.org'

    @expected.body    = read_fixture('announcement_notification')
    expected_text = encode_mail(@expected)
    expected_text.gsub!('-unique_key-', recipient.notifiee_info.unique_key)

    assert_equal expected_text, encode_mail(Mailer.announcement_notification(announcement, recipient.notifiee_info))
  end

  test 'feedback anonymously' do
    @expected.subject = 'Sysmo SEEK Feedback provided - This is a test feedback'
    @expected.to = 'Quentin Jones <quentin@email.com>'
    @expected.from    = 'no-reply@sysmo-db.org'

    @expected.body    = read_fixture('feedback_anon')

    assert_equal encode_mail(@expected), encode_mail(Mailer.feedback(users(:aaron), 'This is a test feedback', 'testing the feedback message', true))
  end

  test 'feedback non anonymously' do
    @expected.subject = 'Sysmo SEEK Feedback provided - This is a test feedback'
    @expected.to = 'Quentin Jones <quentin@email.com>'
    @expected.from = 'no-reply@sysmo-db.org'
    @expected.reply_to = 'Aaron Spiggle <aaron@email.com>'

    @expected.body = read_fixture('feedback_non_anon')
    expected_text = encode_mail(@expected)
    expected_text.gsub!('-person_id-', users(:aaron).person.id.to_s)

    assert_equal expected_text, encode_mail(Mailer.feedback(users(:aaron), 'This is a test feedback', 'testing the feedback message', false))
  end

  test 'request contact' do
    @expected.to = ['Maximilian Maxi-Mum <maximal_person@email.com>']
    @expected.from = 'no-reply@sysmo-db.org'
    @expected.body = read_fixture('request_contact')
    @owner = Factory(:max_person)
    details = 'here are some more details.'
    presentation = Factory :ppt_presentation, contributor: @owner
    @expected.subject = 'A Sysmo SEEK member requests to discuss with you regarding '+ presentation.title

    requester = Factory(:person, first_name: 'Aaron', last_name: 'Spiggle')
    @expected.reply_to = requester.person.email_with_name

    expected_text = encode_mail(@expected)
    expected_text.gsub!('-person_id-', requester.person.id.to_s)
    expected_text.gsub!('-resource_id-', presentation.id.to_s)
    expected_text.gsub!('--title--', presentation.title.to_s)
    assert_equal expected_text, encode_mail(Mailer.request_contact(requester, presentation, details))
  end

  test 'request publish approval' do
    gatekeeper = Factory(:asset_gatekeeper, first_name: 'Gatekeeper', last_name: 'Last')
    person = Factory(:person, project: gatekeeper.projects.first)
    resources = [Factory(:data_file, projects: gatekeeper.projects, title: 'Picture', contributor:person), Factory(:teusink_model, projects: gatekeeper.projects, title: 'Teusink', contributor:person)]
    requester = Factory(:person, first_name: 'Aaron', last_name: 'Spiggle')

    @expected.subject = 'A Sysmo SEEK member requested your approval to publish some items.'

    @expected.to = gatekeeper.email_with_name
    @expected.from = 'no-reply@sysmo-db.org'
    @expected.reply_to = requester.person.email_with_name

    @expected.body = read_fixture('request_publish_approval')

    expected_text = encode_mail(@expected)
    expected_text.gsub!('-person_id-', gatekeeper.id.to_s)
    expected_text.gsub!('-df_id-', resources[0].id.to_s)
    expected_text.gsub!('-model_id-', resources[1].id.to_s)
    expected_text.gsub!('-requester_id-', requester.person.id.to_s)

    assert_equal expected_text, encode_mail(Mailer.request_publish_approval(gatekeeper, requester, resources))
  end

  test 'request publishing' do
    @expected.subject = 'A Sysmo SEEK member requests you make some items public'
    @expected.to = 'Datafile Owner <data_file_owner@email.com>'
    @expected.from = 'no-reply@sysmo-db.org'
    @expected.reply_to = 'Aaron Spiggle <aaron@email.com>'

    @expected.body = read_fixture('request_publishing')

    publisher = people(:aaron_person)
    owner = people(:person_for_datafile_owner)

    expected_text = encode_mail(@expected)
    expected_text.gsub!('-person_id-', publisher.id.to_s)

    resources = [assays(:metabolomics_assay), data_files(:picture), models(:teusink), assays(:metabolomics_assay2), data_files(:sysmo_data_file)]

    assert_equal expected_text, encode_mail(Mailer.request_publishing(owner, publisher, resources))
  end

  test 'gatekeeper approval feedback' do
    gatekeeper = Factory(:asset_gatekeeper, first_name: 'Gatekeeper', last_name: 'Last')
    person = Factory(:person, project: gatekeeper.projects.first)
    item = Factory(:data_file, projects: gatekeeper.projects, title: 'Picture', contributor:person)
    items_and_comments = [{ item: item, comment: nil }]
    requester = Factory(:person, first_name: 'Aaron', last_name: 'Spiggle')
    @expected.subject = "A Sysmo SEEK #{I18n.t('asset_gatekeeper').downcase} approved your publishing requests."

    @expected.to = requester.email_with_name
    @expected.from = 'no-reply@sysmo-db.org'
    @expected.reply_to = gatekeeper.email_with_name

    @expected.body = read_fixture('gatekeeper_approval_feedback')
    expected_text = encode_mail(@expected)
    expected_text.gsub!('-person_id-', gatekeeper.id.to_s)
    expected_text.gsub!('-df_id-', item.id.to_s)
    expected_text.gsub!('-asset_gatekeeper-', I18n.t('asset_gatekeeper').downcase)

    assert_equal expected_text, encode_mail(Mailer.gatekeeper_approval_feedback(requester, gatekeeper, items_and_comments))
  end

  test 'gatekeeper reject feedback' do
    gatekeeper = Factory(:asset_gatekeeper, first_name: 'Gatekeeper', last_name: 'Last')
    person = Factory(:person, project: gatekeeper.projects.first)
    item = Factory(:data_file, projects: gatekeeper.projects, title: 'Picture',contributor:person)
    items_and_comments = [{ item: item, comment: 'not ready' }]

    requester = Factory(:person, first_name: 'Aaron', last_name: 'Spiggle')
    @expected.subject = "A Sysmo SEEK #{I18n.t('asset_gatekeeper').downcase} rejected your publishing requests."

    @expected.to = requester.email_with_name
    @expected.from = 'no-reply@sysmo-db.org'
    @expected.reply_to = gatekeeper.email_with_name

    @expected.body = read_fixture('gatekeeper_reject_feedback')

    expected_text = encode_mail(@expected)
    expected_text.gsub!('-person_id-', gatekeeper.id.to_s)
    expected_text.gsub!('-df_id-', item.id.to_s)
    expected_text.gsub!('-asset_gatekeeper-', I18n.t('asset_gatekeeper').downcase)

    assert_equal expected_text, encode_mail(Mailer.gatekeeper_reject_feedback(requester, gatekeeper, items_and_comments))
  end

  test 'forgot_password' do
    @expected.subject = 'Sysmo SEEK - Password reset'
    @expected.to = 'Aaron Spiggle <aaron@email.com>'
    @expected.from    = 'no-reply@sysmo-db.org'

    @expected.body    = read_fixture('forgot_password')

    u = users(:aaron)
    u.reset_password_code_until = 1.day.from_now
    u.reset_password_code = 'fred'

    assert_equal encode_mail(@expected), encode_mail(Mailer.forgot_password(users(:aaron)))
  end

  test 'contact_admin_new_user' do

    new_registree = Factory(:person,first_name:'Fred',last_name:'Jones', email:'fredjones@email.com')

    @expected.subject = 'Sysmo SEEK member signed up'
    @expected.to = 'Quentin Jones <quentin@email.com>'
    @expected.from = 'no-reply@sysmo-db.org'
    @expected.reply_to = 'Fred Jones <fredjones@email.com>'

    @expected.body = read_fixture('contact_admin_new_user')

    expected_text = encode_mail(@expected)
    expected_text.gsub!('-person_id-', new_registree.id.to_s)

    assert_equal expected_text,
                 encode_mail(Mailer.contact_admin_new_user(new_registree.user))
  end


  test 'welcome' do
    @expected.subject = 'Welcome to Sysmo SEEK'
    @expected.to = 'Quentin Jones <quentin@email.com>'
    @expected.from = 'no-reply@sysmo-db.org'

    @expected.body = read_fixture('welcome')

    expected_text = encode_mail(@expected)
    expected_text.gsub!('-person_id-', users(:quentin).person.id.to_s)
    expected_text.gsub!('-join_project-', Seek::Help::HelpDictionary.instance.help_link(:join_project))
    expected_text.gsub!('-programme_manage-', Seek::Help::HelpDictionary.instance.help_link(:programme_self_management))
    expected_text.gsub!('-user_guide-', Seek::Help::HelpDictionary.instance.help_link(:get_started))

    assert_equal expected_text, encode_mail(Mailer.welcome(users(:quentin)))
  end

  test 'project changed' do
    project_admin = Factory(:project_administrator)
    project = project_admin.projects.first

    @expected.subject = "The Sysmo SEEK Project #{project.title} information has been changed"
    @expected.to = "Quentin Jones <quentin@email.com>, #{project_admin.email_with_name}"
    @expected.from = 'no-reply@sysmo-db.org'
    @expected.body = read_fixture('project_changed')

    expected_text = encode_mail(@expected)
    expected_text.gsub!('-pr_id-', project.id.to_s)

    assert_equal expected_text, encode_mail(Mailer.project_changed(project))
  end

  test 'programme activation required' do
    creator = Factory(:programme_administrator)
    programme = creator.programmes.first
    @expected.subject = "The Sysmo SEEK Programme #{programme.title} was created and needs activating"
    @expected.to = 'Quentin Jones <quentin@email.com>'
    @expected.from = 'no-reply@sysmo-db.org'
    @expected.body = read_fixture('programme_activation_required')

    expected_text = encode_mail(@expected)
    expected_text.gsub!('-prog_id-', programme.id.to_s)
    expected_text.gsub!('-person_id-', creator.id.to_s)
    expected_text.gsub!('-person_email_address-', creator.email)

    assert_equal expected_text, encode_mail(Mailer.programme_activation_required(programme, creator))
  end

  test 'programme activated' do
    creator = Factory(:programme_administrator)
    programme = creator.programmes.first

    @expected.subject = "The Sysmo SEEK Programme #{programme.title} has been activated"
    @expected.to = creator.email_with_name
    @expected.from = 'no-reply@sysmo-db.org'
    @expected.body = read_fixture('programme_activated')

    expected_text = encode_mail(@expected)
    expected_text.gsub!('-prog_id-', programme.id.to_s)
    expected_text.gsub!('-prog_title-', programme.title)

    assert_equal expected_text, encode_mail(Mailer.programme_activated(programme))
  end

  test 'programme rejected' do
    creator = Factory(:programme_administrator)
    programme = creator.programmes.first

    @expected.subject = "The Sysmo SEEK Programme #{programme.title} has been rejected"
    @expected.to = creator.email_with_name
    @expected.from = 'no-reply@sysmo-db.org'
    @expected.body = read_fixture('programme_rejected')

    expected_text = encode_mail(@expected)
    expected_text.gsub!('-prog_id-', programme.id.to_s)
    expected_text.gsub!('-prog_title-', programme.title)

    message = 'blah blah blah'
    assert_equal expected_text, encode_mail(Mailer.programme_rejected(programme, message))
  end

  test 'test mail' do
    with_config_value(:application_name, 'SEEK EMAIL TEST') do
      with_config_value(:site_base_host, 'http://fred.com') do
        email = Mailer.test_email('fred@email.com')
        assert_not_nil email
        assert_equal 'SEEK Configuration Email Test', email.subject
        assert_equal ['no-reply@sysmo-db.org'], email.from
        assert_equal ['fred@email.com'], email.to

        assert email.body.include?('This is a test email sent from SEEK EMAIL TEST configured with the Site base URL of http://fred.com')
      end
    end
  end

  test 'test mail with https host' do
    with_config_value(:application_name, 'SEEK EMAIL TEST') do
      with_config_value(:site_base_host, 'https://securefred.com:1337') do
        email = Mailer.test_email('fred@email.com')
        assert_not_nil email
        assert_equal 'SEEK Configuration Email Test', email.subject
        assert_equal ['no-reply@sysmo-db.org'], email.from
        assert_equal ['fred@email.com'], email.to

        assert email.body.include?('This is a test email sent from SEEK EMAIL TEST configured with the Site base URL of https://securefred.com:1337')
      end
    end
  end

  test 'request join project with new institution' do
    with_config_value(:application_name, 'SEEK EMAIL TEST') do
      with_config_value(:site_base_host, 'https://hub.com') do
        project = Factory(:project)
        institution = Institution.new({title:'My lovely institution', web_page:'http://inst.org', country:'DE'})
        comments = 'some comments'
        person = Factory(:person)
        log = ProjectMembershipMessageLog.log_request(sender:person, project:project, institution:institution, comments:comments)
        email = Mailer.request_join_project(person.user, project, institution.to_json,comments, log)
        refute_nil email
        refute_nil email.body
      end
    end
  end

  test 'request join project existing institution' do
    with_config_value(:application_name, 'SEEK EMAIL TEST') do
      with_config_value(:site_base_host, 'https://securefred.com:1337') do
        project = Factory(:project)
        institution = Factory(:institution)
        comments = 'some comments'
        person = Factory(:person)
        log = ProjectMembershipMessageLog.log_request(sender:person, project:project, institution:institution, comments:comments)
        email = Mailer.request_join_project(person.user, project, institution.to_json,comments, log)
        refute_nil email
        refute_nil email.body

      end
    end
  end

  test 'request create project for programme' do
    with_config_value(:application_name, 'SEEK EMAIL TEST') do
      with_config_value(:site_base_host, 'https://securefred.com:1337') do
        programme_admin = Factory(:programme_administrator)
        programme = programme_admin.programmes.first
        refute_empty programme.programme_administrators
        project = Project.new(title:'My lovely project')
        institution = Factory(:institution)
        sender = Factory(:person)
        log = ProjectCreationMessageLog.log_request(sender:sender, programme:programme, project:project, institution:institution)
        email = Mailer.request_create_project_for_programme(sender.user, programme, project.to_json, institution.to_json,log)
        refute_nil email
        refute_nil email.body
        assert_equal [programme_admin.email],email.to
      end
    end
  end

  test 'request create project for programme admins' do
    admin = Factory(:admin)
    programme_admin = Factory(:programme_administrator)
    programme = programme_admin.programmes.first
    with_config_value(:application_name, 'SEEK EMAIL TEST') do
      with_config_value(:site_base_host, 'https://securefred.com:1337') do        
        with_config_value(:managed_programme_id, programme.id) do
          refute_empty programme.programme_administrators
          project = Project.new(title:'My lovely project')
          institution = Factory(:institution)
          sender = Factory(:person)
          log = ProjectCreationMessageLog.log_request(sender:sender, programme:programme, project:project, institution: institution)
          email = Mailer.request_create_project_for_programme_admins(sender.user, programme, project.to_json, institution.to_json,log)
          refute_nil email
          refute_nil email.body
          assert_equal Person.admins.collect(&:email), email.to
        end        
      end
    end
  end

  test 'request create project' do
    with_config_value(:application_name, 'SEEK EMAIL TEST') do
      with_config_value(:site_base_host, 'https://securefred.com:1337') do
        project = Project.new(title:'My lovely project')
        institution = Factory(:institution)
        sender = Factory(:person)
        log = ProjectCreationMessageLog.log_request(sender:sender, project:project, institution:institution)
        email = Mailer.request_create_project(sender.user, project.to_json, institution.to_json,log)
        refute_nil email
        refute_nil email.body
      end
    end
  end

  test 'request create project and programme' do
    with_config_value(:application_name, 'SEEK EMAIL TEST') do
      with_config_value(:site_base_host, 'https://securefred.com:1337') do
        institution = Institution.new({title:'My lovely institution', web_page:'http://inst.org', country:'DE'})
        project = Project.new(title:'My lovely project')
        programme = Programme.new(title:'My lovely programme')
        sender = Factory(:person)
        log = ProjectCreationMessageLog.log_request(sender:sender, programme:programme, project:project, institution:institution)
        email = Mailer.request_create_project_and_programme(sender.user, programme.to_json, project.to_json, institution.to_json,log)
        refute_nil email
        refute_nil email.body        
      end
    end
  end

  test 'join project rejected' do
    project = Factory(:project,title:'project to join')
    requester = Factory(:person)
    comments = "You are evil"
    email = Mailer.join_project_rejected(requester, project, comments)
    refute_nil email
    refute_nil email.body
    assert_equal "Your request to join the Project, project to join, hasn't been approved",email.subject
  end

  test 'create project rejected' do
    requester = Factory(:person)
    project_name='My Project'
    comments = 'load of rubbish'
    email = Mailer.create_project_rejected(requester,project_name,comments)
    refute_nil email
    refute_nil email.body
  end


  private

  def encode_mail(message)
    message.encoded.gsub(/Message-ID: <.+>/, '').gsub(/Date: .+/, '')
  end
end
