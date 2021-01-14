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
    log.resource = nil
    refute log.valid?

    log = valid_log
    log.sender = nil
    refute log.valid?

    log = valid_log
    log.details = ''
    assert log.valid?
    log.details = nil
    assert log.valid?

    # resource must be a project for project membership request
    log = valid_log
    log.message_type = MessageLog::PROJECT_MEMBERSHIP_REQUEST
    log.resource = Factory(:data_file)
    refute log.valid?
  end

  test 'project_membership_scope' do
    MessageLog.destroy_all
    resource = Factory(:project)
    sender = Factory(:person)
    log1 = MessageLog.create(resource: resource, sender: sender, details: 'blah blah', message_type: MessageLog::PROJECT_MEMBERSHIP_REQUEST)
    log2 = MessageLog.create(resource: resource, sender: sender, details: 'blah blah', message_type: MessageLog::PROJECT_MEMBERSHIP_REQUEST)
    log3 = MessageLog.create(resource: resource, sender: sender, details: 'blah blah', message_type: 2)

    logs = MessageLog.project_membership_requests
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

    logs = MessageLog.recent
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
    log3.resource = Factory(:project)
    log3.save!
    log4 = nil
    travel_to(Time.now - 18.hours) do
      log4 = valid_log
      log4.resource = log.resource
      log4.sender = log.sender
      log4.save!
    end

    logs = MessageLog.recent_project_membership_requests(log.sender, log.resource)
    assert_equal [log], logs
  end

  test 'log project membership request' do
    proj = Factory(:project)
    sender = Factory(:person)
    institution = Institution.new(title:'new inst',country:'DE')
    assert_difference('MessageLog.count') do
      MessageLog.log_project_membership_request(sender, proj, institution, 'some comments')
    end
    log = MessageLog.last
    assert_equal proj, log.resource
    assert_equal sender, log.sender
    assert_equal MessageLog::PROJECT_MEMBERSHIP_REQUEST, log.message_type
    details = JSON.parse(log.details)
    assert_equal 'some comments',details['comments']
    assert_equal 'new inst', details['institution']['title']
    assert_nil details['institution']['id']
    assert_equal 'DE',details['institution']['country']
  end

  test 'log project creation request' do
    requester = Factory(:person)
    programme = Factory(:programme)
    project = Project.new(title:'a project',web_page:'http://page')
    institution = Institution.new(title:'an inst',country:'FR')
    assert_difference('MessageLog.count') do
      MessageLog.log_project_creation_request(requester, programme, project, institution)
    end
    log = MessageLog.last
    assert_equal requester, log.resource
    assert_equal requester, log.sender
    assert_equal MessageLog::PROJECT_CREATION_REQUEST, log.message_type
    details = JSON.parse(log.details)
    assert_equal programme.title,details['programme']['title']
    assert_equal programme.id,details['programme']['id']
    assert_equal 'a project',details['project']['title']
    assert_nil details['project']['id']
    assert_equal 'an inst', details['institution']['title']
    assert_nil details['institution']['id']
    assert_equal 'FR',details['institution']['country']
  end

  test 'responded' do
    log = MessageLog.new
    assert_nil log.response
    refute log.responded?

    log.response=''
    refute log.responded?

    log.response = 'Accepted'
    assert log.responded?
  end

  test 'respond' do
    log=valid_log
    log.save!
    refute log.responded?
    assert_nil log.response

    log.respond('hello')
    log.reload

    assert log.responded?
    assert_equal 'hello',log.response
  end

  test 'project creation request scope' do
    project = Project.new(title: 'my project')
    project2 = Project.new(title: 'my project 2')
    person = Factory(:person)
    admin = Factory(:admin)
    institution = Factory(:institution)

    log1=MessageLog.log_project_creation_request(person,Factory(:programme),project,institution)
    log2=MessageLog.log_project_creation_request(person,Factory(:programme),project2,institution)

    assert_equal [log1,log2],MessageLog.project_creation_requests.sort_by(&:id)
    assert_equal [log1,log2],MessageLog.pending_project_creation_requests.sort_by(&:id)

    log1.respond('Accepted')
    assert_equal [log1,log2],MessageLog.project_creation_requests.sort_by(&:id)
    assert_equal [log2],MessageLog.pending_project_creation_requests
  end

  test 'pending project join requests' do

    person1 = Factory(:project_administrator)
    person2 = Factory(:project_administrator)
    project1 = person1.projects.first
    project2 = person2.projects.first
    project3 = Factory(:project)


    log1a = MessageLog.log_project_membership_request(Factory(:person),project1,Factory(:institution),'')
    log1b = MessageLog.log_project_membership_request(Factory(:person),project1,Factory(:institution),'')
    log2 = MessageLog.log_project_membership_request(Factory(:person),project2,Factory(:institution),'')


    assert_equal [log1a,log1b],MessageLog.pending_project_join_requests([project1]).sort_by(&:id)
    assert_equal [log1a,log1b,log2],MessageLog.pending_project_join_requests([project1,project2]).sort_by(&:id)
    assert_equal [log2],MessageLog.pending_project_join_requests([project2]).sort_by(&:id)

    log1a.respond('Rejected')
    assert_equal [log1b],MessageLog.pending_project_join_requests([project1]).sort_by(&:id)
    assert_equal [log1b,log2],MessageLog.pending_project_join_requests([project1,project2]).sort_by(&:id)
    log1b.respond('Accepted')
    assert_empty MessageLog.pending_project_join_requests([project1])
    assert_equal [log2],MessageLog.pending_project_join_requests([project1,project2])
    log2.respond('Rejected')
    assert_empty MessageLog.pending_project_join_requests([project2])

    assert_empty MessageLog.pending_project_join_requests([])

  end

  test 'destroy when person is' do

    MessageLog.destroy_all

    person1 = Factory(:person)
    person2 = Factory(:person)

    project = Project.new(title: 'my project')
    institution = Factory(:institution)

    MessageLog.log_project_creation_request(person1,Factory(:programme),project,institution)
    MessageLog.log_project_creation_request(person2,Factory(:programme),project,institution)

    project = Factory(:project)
    MessageLog.log_project_membership_request(person1,project,Factory(:institution),'')
    MessageLog.log_project_membership_request(person2,project,Factory(:institution),'')


    assert_difference('MessageLog.count',-2) do
      assert_difference('Person.count',-1) do
        disable_authorization_checks do
          person1.destroy
        end
      end
    end

    assert_equal 2, MessageLog.all.count
    assert_equal [person2],MessageLog.all.collect(&:sender).uniq

  end

  test 'sent by self' do
    person = Factory(:person)
    log = MessageLog.log_project_creation_request(person,Factory(:programme),Factory(:project),Factory(:institution))
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


  private

  def valid_log
    resource = Factory(:project)
    sender = Factory(:person)
    MessageLog.new(resource: resource, sender: sender, details: 'blah blah', message_type: MessageLog::PROJECT_MEMBERSHIP_REQUEST)


  end
end
