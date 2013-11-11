require 'test_helper'

class SendAnnouncementEmailsJobTest < ActiveSupport::TestCase

  def setup
    @val = Seek::Config.email_enabled
    Seek::Config.email_enabled=true
    Delayed::Job.delete_all
  end

  def teardown
    Delayed::Job.delete_all
    Seek::Config.email_enabled=@val
  end

  test "exists" do
    site_announcement_id = 1
    from_notifiee_id = 1
    assert !SendAnnouncementEmailsJob.exists?(site_announcement_id,from_notifiee_id)
    assert_difference("Delayed::Job.count",1) do
      Delayed::Job.enqueue SendAnnouncementEmailsJob.new(site_announcement_id,from_notifiee_id)
    end

    assert SendAnnouncementEmailsJob.exists?(site_announcement_id,from_notifiee_id)

    job=Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    assert !SendAnnouncementEmailsJob.exists?(site_announcement_id,from_notifiee_id),"Should ignore locked jobs"

    job.locked_at=nil
    job.failed_at = Time.now
    job.save!
    assert !SendAnnouncementEmailsJob.exists?(site_announcement_id,from_notifiee_id),"Should ignore failed jobs"
  end

  test "create job" do
      site_announcement_id = 1
      from_notifiee_id = 1
      assert_difference("Delayed::Job.count",1) do
        SendAnnouncementEmailsJob.create_job(site_announcement_id,from_notifiee_id)
      end

      job = Delayed::Job.first
      assert_equal 3,job.priority

      assert_no_difference("Delayed::Job.count") do
        SendAnnouncementEmailsJob.create_job(site_announcement_id,from_notifiee_id)
      end
  end


  test "perform" do
    Delayed::Job.delete_all
    BATCHSIZE=50
    from_notifiee_id = 1
    notifiee1 = Factory(:notifiee_info, :id => 10)
    notifiee2 = Factory(:notifiee_info, :id => 60)
    site_announcement = SiteAnnouncement.create(:title => 'test announcement', :body => 'test', :email_notification => true)
    assert SendAnnouncementEmailsJob.exists?(site_announcement.id,1)
    assert_emails 1 do
      SendAnnouncementEmailsJob.new(site_announcement.id, 1).perform
    end

    from_new_notifiee_id = from_notifiee_id + BATCHSIZE + 1
    assert SendAnnouncementEmailsJob.exists?(site_announcement.id,from_new_notifiee_id)
    assert_emails 1 do
      SendAnnouncementEmailsJob.new(site_announcement.id, from_new_notifiee_id).perform
    end
  end
end