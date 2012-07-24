class ProjectSubscriptionJob < Struct.new(:project_subscription_id)

  def perform
    ps = ProjectSubscription.find_by_id(project_subscription_id)
    if ps
      items = all_in_project(ps)
      items.each do |item|
        item.subscriptions << Subscription.new(:person => ps.person, :project_subscription_id => project_subscription_id) unless item.subscribed?(ps.person)
      end
    end
  end

  def self.exists? project_subscription_id
    Delayed::Job.find(:first, :conditions => ['handler = ? AND locked_at IS ? AND failed_at IS ?', ProjectSubscriptionJob.new(project_subscription_id).to_yaml, nil, nil]) != nil
  end

  def self.create_job project_subscription_id, t=15.seconds.from_now, priority=0
    Delayed::Job.enqueue(ProjectSubscriptionJob.new(project_subscription_id), priority, t) unless exists? project_subscription_id
  end

  def all_in_project project_subscription
    all = project_subscription.subscribable_types.map(&:constantize).collect do |klass|
      if klass.reflect_on_association(:projects)
        klass.scoped(:include => :projects)
      else
        klass.all
      end
    end.flatten
    all.select {|item| item.projects.include? project_subscription.project}
  end
end