require 'test_helper'

class MessageLogTest < ActiveSupport::TestCase
  test 'create' do
    log = valid_log
    log.save!
    log.reload
    assert log.created_at <= Time.now
  end

  test 'validation' do
    log = valid_log
    assert log.valid?
    log.message_type = nil
    refute log.valid?

    log = valid_log
    log.subject = nil
    refute log.valid?

    log = valid_log
    log.sender = nil
    refute log.valid?

    log = valid_log
    log.details = ''
    assert log.valid?
    log.details = nil
    assert log.valid?

    # subject must be a project for project membership request
    log = valid_log
    assert log.project_membership_request?
    log.subject = Factory(:data_file)
    refute log.valid?
  end

  test 'project_membership_scope' do
    MessageLog.destroy_all
    subject = Factory(:project)
    sender = Factory(:person)
    log1 = ProjectMembershipMessageLog.create(subject: subject, sender: sender, details: 'blah blah')
    log2 = ProjectMembershipMessageLog.create(subject: subject, sender: sender, details: 'blah blah')
    log3 = ProjectMembershipMessageLog.create(subject: subject, sender: sender, details: 'blah blah', message_type: 2)

    logs = ProjectMembershipMessageLog.all
    assert_equal [log1, log2].sort, logs.sort
  end

  test 'recent_scope' do
    MessageLog.destroy_all
    assert_equal 12.hours, MessageLog::RECENT_PERIOD
    recent = nil
    older = nil
    travel_to(Time.now - 6.hours) do
      recent = valid_log
      recent.save!
    end
    travel_to(Time.now - 18.hours) do
      older = valid_log
      older.save!
    end

    logs = ProjectMembershipMessageLog.recent
    assert_includes logs, recent
    refute_includes logs, older
  end

  test 'recent project membership requests' do
    log = valid_log
    log.save!
    log2 = valid_log
    log2.sender = Factory(:person)
    log2.save!
    log3 = valid_log
    log3.subject = Factory(:project)
    log3.save!
    log4 = nil
    travel_to(Time.now - 18.hours) do
      log4 = valid_log
      log4.subject = log.subject
      log4.sender = log.sender
      log4.save!
    end

    logs = ProjectMembershipMessageLog.recent_requests(log.sender, log.subject)
    assert_equal [log], logs
  end

  test 'log project membership request' do
    proj = Factory(:project)
    sender = Factory(:person)
    institution = Institution.new(title: 'new inst', country: 'DE')
    assert_difference('ProjectMembershipMessageLog.count') do
      ProjectMembershipMessageLog.log_request(sender, proj, institution, 'some comments')
    end
    log = ProjectMembershipMessageLog.last
    assert_equal proj, log.subject
    assert_equal sender, log.sender
    assert_equal 'project_membership_request', log.message_type
    details = JSON.parse(log.details)
    assert_equal 'some comments', details['comments']
    assert_equal 'new inst', details['institution']['title']
    assert_nil details['institution']['id']
    assert_equal 'DE', details['institution']['country']
  end

  test 'log project creation request' do
    requester = Factory(:person)
    programme = Factory(:programme)
    project = Project.new(title: 'a project', web_page: 'http://page')
    institution = Institution.new(title: 'an inst', country: 'FR')
    assert_difference('ProjectCreationMessageLog.count') do
      ProjectCreationMessageLog.log_request(requester, programme, project, institution)
    end
    log = ProjectCreationMessageLog.last
    assert_equal requester, log.subject
    assert_equal requester, log.sender
    assert_equal 'project_creation_request', log.message_type
    assert log.project_creation_request?
    details = JSON.parse(log.details)
    assert_equal programme.title, details['programme']['title']
    assert_equal programme.id, details['programme']['id']
    assert_equal 'a project', details['project']['title']
    assert_nil details['project']['id']
    assert_equal 'an inst', details['institution']['title']
    assert_nil details['institution']['id']
    assert_equal 'FR', details['institution']['country']
  end

  test 'responded' do
    log = ProjectCreationMessageLog.new
    assert_nil log.response
    refute log.responded?

    log.response = ''
    refute log.responded?

    log.response = 'Accepted'
    assert log.responded?
  end

  test 'respond' do
    log = valid_log
    log.save!
    refute log.responded?
    assert_nil log.response

    log.respond('hello')
    log.reload

    assert log.responded?
    assert_equal 'hello', log.response
  end

  test 'project creation request scope' do
    project = Project.new(title: 'my project')
    project2 = Project.new(title: 'my project 2')
    person = Factory(:person)
    admin = Factory(:admin)
    institution = Factory(:institution)

    log1 = ProjectCreationMessageLog.log_request(person, Factory(:programme), project, institution)
    log2 = ProjectCreationMessageLog.log_request(person, Factory(:programme), project2, institution)

    assert_equal [log1, log2], ProjectCreationMessageLog.all.sort_by(&:id)
    assert_equal [log1, log2], ProjectCreationMessageLog.pending_requests.sort_by(&:id)

    log1.respond('Accepted')
    assert_equal [log1, log2], ProjectCreationMessageLog.all.sort_by(&:id)
    assert_equal [log2], ProjectCreationMessageLog.pending_requests
  end

  test 'pending project join requests' do
    person1 = Factory(:project_administrator)
    person2 = Factory(:project_administrator)
    project1 = person1.projects.first
    project2 = person2.projects.first
    project3 = Factory(:project)

    log1a = ProjectMembershipMessageLog.log_request(Factory(:person), project1, Factory(:institution), '')
    log1b = ProjectMembershipMessageLog.log_request(Factory(:person), project1, Factory(:institution), '')
    log2 = ProjectMembershipMessageLog.log_request(Factory(:person), project2, Factory(:institution), '')

    assert_equal [log1a, log1b], ProjectMembershipMessageLog.pending_requests([project1]).sort_by(&:id)
    assert_equal [log1a, log1b, log2], ProjectMembershipMessageLog.pending_requests([project1, project2]).sort_by(&:id)
    assert_equal [log2], ProjectMembershipMessageLog.pending_requests([project2]).sort_by(&:id)

    log1a.respond('Rejected')
    assert_equal [log1b], ProjectMembershipMessageLog.pending_requests([project1]).sort_by(&:id)
    assert_equal [log1b, log2], ProjectMembershipMessageLog.pending_requests([project1, project2]).sort_by(&:id)
    log1b.respond('Accepted')
    assert_empty ProjectMembershipMessageLog.pending_requests([project1])
    assert_equal [log2], ProjectMembershipMessageLog.pending_requests([project1, project2])
    log2.respond('Rejected')
    assert_empty ProjectMembershipMessageLog.pending_requests([project2])

    assert_empty ProjectMembershipMessageLog.pending_requests([])
  end

  test 'destroy when person is' do
    MessageLog.destroy_all

    person1 = Factory(:person)
    person2 = Factory(:person)

    project = Project.new(title: 'my project')
    institution = Factory(:institution)

    ProjectCreationMessageLog.log_request(person1, Factory(:programme), project, institution)
    ProjectCreationMessageLog.log_request(person2, Factory(:programme), project, institution)

    project = Factory(:project)
    ProjectMembershipMessageLog.log_request(person1, project, Factory(:institution), '')
    ProjectMembershipMessageLog.log_request(person2, project, Factory(:institution), '')

    assert_difference('ProjectCreationMessageLog.count', -1) do
      assert_difference('ProjectMembershipMessageLog.count', -1) do
        assert_difference('Person.count', -1) do
          disable_authorization_checks do
            person1.destroy
          end
        end
      end
    end

    assert_equal 1, ProjectCreationMessageLog.count
    assert_equal 1, ProjectMembershipMessageLog.count
    assert_equal [person2], MessageLog.all.collect(&:sender).uniq
  end

  test 'sent by self' do
    person = Factory(:person)
    log = ProjectCreationMessageLog.log_request(person, Factory(:programme), Factory(:project), Factory(:institution))
    User.with_current_user(person.user) do
      assert log.sent_by_self?
    end
    User.with_current_user(Factory(:user)) do
      refute log.sent_by_self?
    end
    User.with_current_user(nil) do
      refute log.sent_by_self?
    end
  end

  test 'log activation email sent' do
    person = Factory(:person)
    log = assert_difference('ActivationEmailMessageLog.count') do
      ActivationEmailMessageLog.log_activation_email(person)
    end
    assert_equal 'activation_email', log.message_type
    assert_equal person, log.sender
    assert_equal person, log.subject
  end

  test 'activation email logs' do
    log1, log2, log3, lo4 = nil
    person = Factory(:person)
    other_person = Factory(:person)

    travel_to(2.days.ago) do
      log2 = ActivationEmailMessageLog.log_activation_email(person)
    end

    travel_to(4.days.ago) do
      log1 = ActivationEmailMessageLog.log_activation_email(person)
    end

    travel_to(1.days.ago) do
      log3 = ActivationEmailMessageLog.log_activation_email(person)
      log4 = ActivationEmailMessageLog.log_activation_email(other_person)
    end

    assert_equal [log1, log2, log3], ActivationEmailMessageLog.activation_email_logs(person)
    assert_equal [log1, log2, log3], person.activation_email_logs
  end

  test 'can respond project creation request' do
    admin = Factory(:admin)
    prog_admin = Factory(:programme_administrator)
    programme = prog_admin.programmes.first
    person = Factory(:person)
    institution = Factory(:institution)
    project = Project.new(title: 'new project')

    # no programme
    log = ProjectCreationMessageLog.log_request(person, nil, project, institution)
    assert log.can_respond_project_creation_request?(admin)
    assert log.can_respond_project_creation_request?(admin.user)
    refute log.can_respond_project_creation_request?(prog_admin)
    refute log.can_respond_project_creation_request?(person)

    # normal programme
    log = ProjectCreationMessageLog.log_request(person, programme, project, institution)
    refute log.can_respond_project_creation_request?(admin)
    assert log.can_respond_project_creation_request?(prog_admin)
    refute log.can_respond_project_creation_request?(person)

    with_config_value(:managed_programme_id, programme.id) do
      # managed programme
      log = ProjectCreationMessageLog.log_request(person, programme, project, institution)
      assert log.can_respond_project_creation_request?(admin)
      assert log.can_respond_project_creation_request?(prog_admin)
      refute log.can_respond_project_creation_request?(person)
    end

    # new programme
    log = ProjectCreationMessageLog.log_request(person, Programme.new(title: 'new programme'), project, institution)
    assert log.can_respond_project_creation_request?(admin)
    refute log.can_respond_project_creation_request?(prog_admin)
    refute log.can_respond_project_creation_request?(person)
  end

  private

  def valid_log
    subject = Factory(:project)
    sender = Factory(:person)
    ProjectMembershipMessageLog.new(subject: subject, sender: sender, details: 'blah blah')
  end
end
