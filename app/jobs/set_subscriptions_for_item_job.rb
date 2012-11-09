class SetSubscriptionsForItemJob < Struct.new(:subscribable_type,:subscribable_id, :project_ids)
  def perform
    subscribable = subscribable_type.constantize.find_by_id(subscribable_id)
    if subscribable
      projects = Project.find(:all, :conditions => ["id IN (?)", project_ids])
      subscribable.set_default_subscriptions projects
    end
  end

  def self.exists? subscribable_type, subscribable_id, project_ids
    Delayed::Job.find(:first, :conditions => ['handler = ? AND locked_at IS ? AND failed_at IS ?', SetSubscriptionsForItemJob.new(subscribable_type,subscribable_id,project_ids).to_yaml, nil, nil]) != nil
  end

  def self.create_job subscribable_type, subscribable_id, project_ids, t=5.seconds.from_now, priority=1
    Delayed::Job.enqueue(SetSubscriptionsForItemJob.new(subscribable_type, subscribable_id, project_ids), priority, t) unless exists?(subscribable_type, subscribable_id, project_ids)
  end
end