class ProjectSubscriptionJob < Struct.new(:project_subscription_id)

  def perform
    ps = ProjectSubscription.find_by_id(project_subscription_id)
    if ps
      all_in_project(ps).each{|item| item.subscriptions.build(:person => ps.person, :project_subscription_id => project_subscription_id) unless item.subscribed?(ps.person) }.each {|i| disable_authorization_checks {i.save(false)} if i.changed_for_autosave?}
    end
  end

  def self.exists? project_subscription_id
    Delayed::Job.find(:first, :conditions => ['handler = ? AND locked_at IS ? AND failed_at IS ?', ProjectSubscriptionJob.new(project_subscription_id).to_yaml, nil, nil]) != nil
  end

  def self.create_job project_subscription_id, t=15.seconds.from_now, priority=0
    Delayed::Job.enqueue(ProjectSubscriptionJob.new(project_subscription_id), priority, t) unless exists? project_subscription_id
  end

  def all_in_project project_subscription
    project_subscription.subscribable_types.map(&:constantize).collect {|klass| if klass.reflect_on_association(:projects) then klass.scoped(:include => :projects) else klass.all end}.flatten.select {|item| item.projects.include? project_subscription.project}
  end
end