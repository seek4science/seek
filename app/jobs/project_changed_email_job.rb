class ProjectChangedEmailJob < SeekJob

  attr_reader :project_id

  def initialize(project)
    @project_id = project.id
  end

  def before(_job)
    # make sure the SMTP,site_base_host configuration is in sync with current SEEK settings
    Seek::Config.smtp_propagate
    Seek::Config.site_base_host_propagate
  end

  def perform_job(job_item)
    if Seek::Config.email_enabled
      Mailer.project_changed(job_item,Seek::Config.site_base_host).deliver
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