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

    refute SendAnnouncementEmailsJob.new(site_announcement_id).exists?
    assert_difference('Delayed::Job.count', 1) do
      Delayed::Job.enqueue SendAnnouncementEmailsJob.new(site_announcement_id)
    end
    assert SendAnnouncementEmailsJob.new(site_announcement_id).exists?

    job = Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    refute SendAnnouncementEmailsJob.new(site_announcement_id).exists?, 'Should ignore locked jobs'

    job.locked_at = nil
    job.failed_at = Time.now
    job.save!
    refute SendAnnouncementEmailsJob.new(site_announcement_id).exists?, 'Should ignore failed jobs'
  end

  test 'create job' do
    site_announcement_id = 1
    assert_difference('Delayed::Job.count') do
      SendAnnouncementEmailsJob.new(site_announcement_id).queue_job
    end

    job = Delayed::Job.first
    assert_equal 3, job.priority

    assert_no_difference('Delayed::Job.count') do
      SendAnnouncementEmailsJob.new(site_announcement_id).queue_job
    end
  end

  test 'perform' do
    Delayed::Job.delete_all
    Person.destroy_all

    FactoryGirl.create_list(:person, SendAnnouncementEmailsJob::BATCHSIZE)
    assert_equal SendAnnouncementEmailsJob::BATCHSIZE + 1, NotifieeInfo.count

    # checks 1 email is sent for the first batch
    site_announcement = SiteAnnouncement.create(title: 'test announcement', body: 'test', email_notification: true)
    assert SendAnnouncementEmailsJob.new(site_announcement.id ).exists?

    Delayed::Job.delete_all
    assert_enqueued_emails SendAnnouncementEmailsJob::BATCHSIZE do
      assert_difference('Delayed::Job.count', 1, 'a new job should have been created for the next batch') do
        SendAnnouncementEmailsJob.new(site_announcement.id).perform
      end
    end

    # ..and 1 email is sent for the 2nd batch
    follow_on_job = SendAnnouncementEmailsJob.new(site_announcement.id, SendAnnouncementEmailsJob::BATCHSIZE)
    assert follow_on_job.exists?
    Delayed::Job.delete_all
    assert_enqueued_emails 1 do
      assert_no_difference('Delayed::Job.count', 'no new jobs should have been created, since there is no need for a new batch') do
        follow_on_job.perform
      end
    end
  end
end
