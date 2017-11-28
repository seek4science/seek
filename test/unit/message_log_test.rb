require 'test_helper'
require 'time_test_helper'

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
    pretend_now_is(Time.now - 6.hours) do
      recent = valid_log
      recent.save!
    end
    pretend_now_is(Time.now - 18.hours) do
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
    pretend_now_is(Time.now - 18.hours) do
      log4 = valid_log
      log4.resource = log.resource
      log4.sender = log.sender
      log4.save!
    end

    logs = MessageLog.recent_project_membership_requests(log.sender, log.resource)
    assert_equal [log], logs
  end

  private

  def valid_log
    resource = Factory(:project)
    sender = Factory(:person)
    MessageLog.new(resource: resource, sender: sender, details: 'blah blah', message_type: MessageLog::PROJECT_MEMBERSHIP_REQUEST)
  end
end
