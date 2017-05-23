class ProjectChangedEmailJob < SeekEmailJob
  attr_reader :project_id

  def initialize(project)
    @project_id = project.id
  end

  def perform_job(job_item)
    if Seek::Config.email_enabled
      Mailer.project_changed(job_item).deliver_now
    end
  end

  def gather_items
    [Project.find(@project_id)]
  end

  # time before the job is run - delay so that if multiple changes are made in a short time on a single email is still sent
  def default_delay
    15.minutes
  end

  def allow_duplicate_jobs?
    false
  end
end
