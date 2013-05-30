class RemoveSubscriptionsForItemJob < Struct.new(:subscribable_type,:subscribable_id,:old_project_ids)
  def perform
    subscribable = subscribable_type.constantize.find_by_id(subscribable_id)
    if subscribable
      projects = Project.where(["id IN (?)", old_project_ids])
      subscribable.remove_subscriptions projects
    end
  end

  def self.exists? subscribable_type, subscribable_id, old_project_ids
    Delayed::Job.where(['handler = ? AND locked_at IS ? AND failed_at IS ?', RemoveSubscriptionsForItemJob.new(subscribable_type,subscribable_id,old_project_ids).to_yaml, nil, nil]).first != nil
  end

  def self.create_job subscribable_type, subscribable_id, old_project_ids, t=5.seconds.from_now, priority=1
    unless exists?(subscribable_type, subscribable_id, old_project_ids)
      Delayed::Job.enqueue(RemoveSubscriptionsForItemJob.new(subscribable_type, subscribable_id, old_project_ids), :priority=>priority, :run_at=>t)
    end

  end
end