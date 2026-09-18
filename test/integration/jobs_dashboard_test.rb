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

  # The url helpers pick up the engine's script_name once a /jobs page has been visited, so the
  # paths being asserted are worked out before the first request.
  test 'pagination offers first and last page links either side of previous and next' do
    25.times { |n| create_finished_job(ReindexingJob.new, scheduled_at: n.minutes.ago, finished_at: n.minutes.ago) }

    get '/jobs/finished/jobs', params: { page: 2 }

    assert_response :success
    assert_select 'nav[aria-label=pagination]' do
      assert_select 'span', text: '2 / 3'
      assert_select 'a', text: 'First page' do |links|
        assert_equal '1', linked_page(links.first)
        assert_nil links.first['disabled']
      end
      assert_select 'a', text: 'Last page' do |links|
        assert_equal '3', linked_page(links.first)
        assert_nil links.first['disabled']
      end
    end

    # On the first page there is nowhere before it to go.
    get '/jobs/finished/jobs', params: { page: 1 }

    assert_response :success
    assert_select 'nav[aria-label=pagination] a[disabled]', text: 'First page'
    assert_select 'nav[aria-label=pagination] a[disabled]', text: 'Previous page'
  end

  test 'back link returns to the SEEK page the dashboard was entered from' do
    entered_from = person_path(FactoryBot.create(:person))

    get '/jobs/queues', headers: { 'HTTP_REFERER' => entered_from }

    assert_response :success
    assert_select 'nav.navbar a[href=?]', entered_from, text: /Back to/

    # Moving around inside the dashboard leaves the entry point in place.
    get '/jobs/finished/jobs', headers: { 'HTTP_REFERER' => '/jobs/queues' }

    assert_response :success
    assert_select 'nav.navbar a[href=?]', entered_from
  end

  test 'back link falls back to the home page, and ignores referers from elsewhere' do
    home = root_path

    get '/jobs/queues'

    assert_response :success
    assert_select 'nav.navbar a[href=?]', home

    get '/jobs/queues', headers: { 'HTTP_REFERER' => 'http://elsewhere.example.com/people/1' }

    assert_response :success
    assert_select 'nav.navbar a[href=?]', home
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
