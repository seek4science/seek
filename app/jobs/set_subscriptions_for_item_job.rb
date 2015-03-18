class SetSubscriptionsForItemJob < SeekJob

  attr_reader :subscribable_type,:subscribable_id,:project_ids

  def initialize subscribable,projects
    @subscribable_type=subscribable.class.name
    @subscribable_id=subscribable.id
    @project_ids=projects.collect(&:id)
  end

  def before(job)
    #make sure the SMTP,site_base_host configuration is in sync with current SEEK settings
    Seek::Config.smtp_propagate
    Seek::Config.site_base_host_propagate
  end

  def perform_job item
    if item
      item.set_default_subscriptions projects
    end
  end

  def gather_items
    [subscribable].compact
  end

  def default_priority
    1
  end

  def default_delay
    5.seconds
  end

  def allow_duplicate_jobs
    false
  end

  def subscribable
    subscribable_type.constantize.find_by_id(subscribable_id)
  end

  def projects
    Project.find(project_ids)
  end
end