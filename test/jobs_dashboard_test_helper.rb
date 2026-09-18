# The Mission Control - Jobs dashboard is wired up against whichever queue adapter
# config.active_job.queue_adapter names when the engine initialises. config/environments/test.rb
# uses :test, which has none of the dashboard's adapter extensions, so tests that exercise the
# dashboard have to point it back at Solid Queue for the duration of the test.
module JobsDashboardTestHelper
  def setup_jobs_dashboard
    ActiveJob::QueueAdapters::SolidQueueAdapter.prepend(ActiveJob::QueueAdapters::SolidQueueExt)
    ActiveJob::QueueAdapters::SolidQueueAdapter.prepend(Seek::JobDashboard::AllConfiguredQueues)
    @original_dashboard_applications = MissionControl::Jobs.applications
    MissionControl::Jobs.applications = MissionControl::Jobs::Applications.new
    MissionControl::Jobs.applications.add('SEEK', solid_queue: ActiveJob::QueueAdapters::SolidQueueAdapter.new)
  end

  def teardown_jobs_dashboard
    MissionControl::Jobs.applications = @original_dashboard_applications
  end

  # A finished job, as Solid Queue would leave it behind once preserve_finished_jobs has kept it.
  def create_finished_job(job, scheduled_at:, finished_at:)
    SolidQueue::Job.create!(queue_name: job.queue_name, class_name: job.class.name,
                            arguments: job.serialize, priority: job.priority.to_i,
                            active_job_id: job.job_id, scheduled_at: scheduled_at,
                            finished_at: finished_at)
  end
end
