# abstract superclass for common methods for handling subscription items, common to SetSubcriptionsForItemJob
# and RemoveSubscriptionForItemJob.
# perform_job methods is implemented in those subclasses
class SubscriptionsForItemJob < SeekJob
  attr_reader :subscribable_type, :subscribable_id, :project_ids

  def before(_job)
    # make sure the SMTP,site_base_host configuration is in sync with current SEEK settings
    Seek::Config.smtp_propagate
    Seek::Config.site_base_host_propagate
  end

  def initialize(subscribable, projects)
    @subscribable_type = subscribable.class.name
    @subscribable_id = subscribable.id
    @project_ids = projects.collect(&:id)
  end

  def gather_items
    [subscribable].compact
  end

  def projects
    Project.find(project_ids)
  end

  def default_priority
    1
  end

  def subscribable
    subscribable_type.constantize.find_by_id(subscribable_id)
  end

  def allow_duplicate_jobs?
    false
  end
end
