require 'test_helper'

class SendAnnouncementEmailsJobTest < ActiveSupport::TestCase
  def setup
    @val = Seek::Config.email_enabled
    Seek::Config.email_enabled = true
  end

  def teardown
    Seek::Config.email_enabled = @val
  end

  test 'perform' do
    Person.destroy_all

    # Create <BATCHSIZE> + 1 people, so at least 2 batches of emails will need to be sent
    FactoryBot.create_list(:person, SendAnnouncementEmailsJob::BATCHSIZE)
    assert_equal SendAnnouncementEmailsJob::BATCHSIZE + 1, NotifieeInfo.count

    site_announcement = nil
    assert_enqueued_with(job: SendAnnouncementEmailsJob) do
      site_announcement = SiteAnnouncement.create(title: 'test announcement', body: 'test', email_notification: true)
    end

    # checks <BATCHSIZE> emails are sent for the first batch
    assert_enqueued_emails(SendAnnouncementEmailsJob::BATCHSIZE) do
      assert_enqueued_with(job: SendAnnouncementEmailsJob, args: [site_announcement, SendAnnouncementEmailsJob::BATCHSIZE]) do # The follow-on job
        SendAnnouncementEmailsJob.perform_now(site_announcement)
      end
    end

    # ..and 1 email is sent for the 2nd batch
    assert_enqueued_emails 1 do
      # no new jobs should have been created, since there is no need for a new batch
      assert_no_enqueued_jobs(only: SendAnnouncementEmailsJob) do
        SendAnnouncementEmailsJob.perform_now(site_announcement, SendAnnouncementEmailsJob::BATCHSIZE)
      end
    end
  end
end
