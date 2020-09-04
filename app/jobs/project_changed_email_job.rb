class ProjectChangedEmailJob < EmailJob
  def perform(project)
    return unless Seek::Config.email_enabled
    Mailer.project_changed(project).deliver_later
  end

  # time before the job is run - delay so that if multiple changes are made in a short time on a single email is still sent
  def default_delay
    15.minutes
  end
end
