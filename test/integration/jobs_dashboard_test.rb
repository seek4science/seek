require 'test_helper'

class JobsDashboardTest < ActionDispatch::IntegrationTest
  include JobsDashboardTestHelper

  def setup
    setup_jobs_dashboard
    admin = FactoryBot.create(:admin)
    post '/session', params: { login: admin.user.login, password: generate_user_password }
  end

  def teardown
    teardown_jobs_dashboard
  end

  test 'queues list includes configured queues that have never had a job' do
    create_finished_job(ReindexingJob.new, scheduled_at: 1.minute.ago, finished_at: 30.seconds.ago)
    never_used = Seek::Util.configured_queue_names - SolidQueue::Job.distinct.pluck(:queue_name)
    assert never_used.any?, 'expected at least one configured queue with no jobs on it'

    get '/jobs/queues'

    assert_response :success
    assert_select 'table.queues tbody tr.queue td', text: QueueNames::INDEXING
    never_used.each do |queue_name|
      message = "#{queue_name} is configured in config/queue.yml but was not listed"
      assert_select 'table.queues tbody tr.queue td', text: queue_name, message: message
    end
  end

  test 'finished jobs list shows how long each job took, matching the single job page' do
    finished_at = 90.seconds.ago.change(usec: 0)
    scheduled_at = 90.seconds.before(finished_at)
    job = create_finished_job(ReindexingJob.new, scheduled_at: scheduled_at, finished_at: finished_at)

    get '/jobs/finished/jobs'

    assert_response :success
    assert_select 'table.jobs.finished thead th', text: 'Duration'
    assert_select 'table.jobs.finished tbody td div[title=?]', I18n.t('tooltips.job_duration')
    assert_select 'table.jobs.finished tbody td', text: '90.0 seconds'

    # The single job page measures the same thing, and now reads identically.
    get "/jobs/jobs/#{job.active_job_id}"

    assert_response :success
    assert_select 'td', text: '90.0 seconds'
  end
end
