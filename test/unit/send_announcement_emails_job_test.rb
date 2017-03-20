require 'test_helper'

class SendAnnouncementEmailsJobTest < ActiveSupport::TestCase
  def setup
    @val = Seek::Config.email_enabled
    Seek::Config.email_enabled = true
    Delayed::Job.delete_all
  end

  def teardown
    Delayed::Job.delete_all
    Seek::Config.email_enabled = @val
  end

  test 'exists' do
    site_announcement_id = 1
    from_notifiee_id = 1
    assert !SendAnnouncementEmailsJob.new(site_announcement_id, from_notifiee_id).exists?
    assert_difference('Delayed::Job.count', 1) do
      Delayed::Job.enqueue SendAnnouncementEmailsJob.new(site_announcement_id, from_notifiee_id)
    end

    assert SendAnnouncementEmailsJob.new(site_announcement_id, from_notifiee_id).exists?

    job = Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    assert !SendAnnouncementEmailsJob.new(site_announcement_id, from_notifiee_id).exists?, 'Should ignore locked jobs'

    job.locked_at = nil
    job.failed_at = Time.now
    job.save!
    assert !SendAnnouncementEmailsJob.new(site_announcement_id, from_notifiee_id).exists?, 'Should ignore failed jobs'
  end

  test 'create job' do
    site_announcement_id = 1
    from_notifiee_id = 1
    assert_difference('Delayed::Job.count', 1) do
      SendAnnouncementEmailsJob.new(site_announcement_id, from_notifiee_id).queue_job
    end

    job = Delayed::Job.first
    assert_equal 3, job.priority

    assert_no_difference('Delayed::Job.count') do
      SendAnnouncementEmailsJob.new(site_announcement_id, from_notifiee_id).queue_job
    end
  end

  test 'perform' do
    Delayed::Job.delete_all

    notifiee1 = Factory(:person).notifiee_info
    temp_notifiee = Factory(:person).notifiee_info

    # this is to create 2 people with notifiee id;s spread greater than BATCHSIZE
    until temp_notifiee.id > (notifiee1.id + SendAnnouncementEmailsJob::BATCHSIZE + 1)
      temp_notifiee.destroy
      temp_notifiee = Factory(:person).notifiee_info
    end
    temp_notifiee.destroy
    notifee2 = Factory(:person).notifiee_info

    # checks 1 email is sent for the first batch
    site_announcement = SiteAnnouncement.create(title: 'test announcement', body: 'test', email_notification: true)
    assert SendAnnouncementEmailsJob.new(site_announcement.id, 1).exists?
    Delayed::Job.delete_all
    assert_emails 1 do
      assert_difference('Delayed::Job.count', 1, 'a new job should have been created for the next batch') do
        SendAnnouncementEmailsJob.new(site_announcement.id, notifiee1.id).perform
      end
    end

    # ..and 1 email is sent for the 2nd batch
    from_new_notifiee_id = notifiee1.id + SendAnnouncementEmailsJob::BATCHSIZE + 1
    assert SendAnnouncementEmailsJob.new(site_announcement.id, from_new_notifiee_id).exists?
    Delayed::Job.delete_all
    assert_emails 1 do
      assert_no_difference('Delayed::Job.count', 'no new jobs should have been created, since there is need for a new batch') do
        SendAnnouncementEmailsJob.new(site_announcement.id, from_new_notifiee_id).perform
      end
    end
  end
end
