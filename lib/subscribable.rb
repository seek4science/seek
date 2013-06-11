module Subscribable
  def self.included klass
    klass.class_eval do
      has_many :subscriptions, :as => :subscribable, :dependent => :destroy, :autosave => true, :before_add => proc {|item, sub| sub.subscribable = item} #,:required_access_to_owner => false,
      after_create :set_subscription_job if self.subscribable?
      after_update :update_subscription_job_if_study_or_assay if self.subscribable?
      extend ClassMethods
    end
  end

  def current_users_subscription
    subscriptions.detect { |ss| ss.person == User.current_user.person }
  end

  def subscribed? person=User.current_user.person
    !subscriptions.detect{|sub| sub.person == person}.nil?
  end

  def subscribed= subscribed
    if subscribed
      subscribe
    else
      unsubscribe
    end
  end

  def subscribe person=User.current_user.person
    subscriptions << Subscription.new(:person => person) unless subscribed?(person)
  end

  def unsubscribe person=User.current_user.person
    subscriptions.detect{|sub| sub.person == person}.try(:destroy)
  end

  def send_immediate_subscriptions activity_log

    if Seek::Config.email_enabled && subscribers_are_notified_of?(activity_log.action)
      subscriptions.each do |subscription|
        if !subscription.person.user.nil? && subscription.person.receive_notifications? && subscription.immediately? && can_view?(subscription.person.user)
          SubMailer.send_immediate_subscription(subscription.person, activity_log).deliver
        end
      end
    end
    
  end

  def subscribers_are_notified_of? action
    self.class.subscribers_are_notified_of? action
  end

  def set_default_subscriptions projects
    unless projects.empty?
      Person.scoped(:include => :project_subscriptions).each do |person|
        project_subscriptions = person.project_subscriptions
        project_subscriptions.each do |ps|
          if projects.include? ps.project
            subscriptions.create(:person => person, :project_subscription_id => ps.id) if !ps.unsubscribed_types.include?(self.class.name) && !self.subscribed?(person)
            #also build subscriptions for studies and assays associating with this investigation
            if self.kind_of?(Investigation)
              self.studies.each do |study|
                study.subscriptions << Subscription.create(:person => person, :project_subscription_id => ps.id) if !study.subscribed?(person)
              end
              self.assays.each do |assay|
                assay.subscriptions << Subscription.create(:person => person, :project_subscription_id => ps.id) if !assay.subscribed?(person)
              end
            end
          end
        end
      end
    end
  end

  def remove_subscriptions projects
    unless projects.empty?
      project_subscription_ids = projects.collect{|project| project.project_subscriptions}.flatten.collect(&:id)
      subscriptions = Subscription.where(['subscribable_type=? AND subscribable_id=? AND project_subscription_id IN (?)', self.class.name, self.id, project_subscription_ids])
      #remove also subcriptions for studies and assays association with this investigation
      if self.kind_of?(Investigation)
        study_ids = self.studies.collect(&:id)
        assay_ids = self.assays.collect(&:id)
        subscriptions |= Subscription.where(['subscribable_type=? AND subscribable_id IN (?) AND project_subscription_id IN (?)', 'Study', study_ids, project_subscription_ids])
        subscriptions |= Subscription.where(['subscribable_type=? AND subscribable_id IN (?) AND project_subscription_id IN (?)', 'Assay', assay_ids, project_subscription_ids])
      end
      subscriptions.each{|s| s.destroy}
    end
  end

  def set_subscription_job
      SetSubscriptionsForItemJob.create_job(self.class.name, self.id, self.projects.collect(&:id))
  end

  def update_subscription_job_if_study_or_assay
    if self.kind_of?(Study) && self.investigation_id_changed?
      #update subscriptions for study
      old_investigation_id = self.investigation_id_was
      old_investigation = Investigation.find_by_id old_investigation_id
      project_ids_to_remove = old_investigation.nil? ? [] : old_investigation.projects.collect(&:id)
      project_ids_to_add = self.investigation.projects.collect(&:id)
      update_subscriptions_for self, project_ids_to_add, project_ids_to_remove
      #update subscriptions for assays associated with this study
      self.assays.each do |assay|
        update_subscriptions_for assay, project_ids_to_add, project_ids_to_remove
      end
    elsif self.kind_of?(Assay) && self.study_id_changed?
      old_study_id = self.study_id_was
      old_study = Study.find_by_id old_study_id
      project_ids_to_remove = old_study.nil? ? [] : old_study.projects.collect(&:id)
      project_ids_to_add = self.study.projects.collect(&:id)
      update_subscriptions_for self, project_ids_to_add, project_ids_to_remove
    end
  end

  module ClassMethods
    def subscribers_are_notified_of? action
      action=="create" || action == "update"
    end
  end

  private

  def update_subscriptions_for item, project_ids_to_add, project_ids_to_remove
    SetSubscriptionsForItemJob.create_job(item.class.name, item.id, project_ids_to_add)
    RemoveSubscriptionsForItemJob.create_job(item.class.name, item.id, project_ids_to_remove)
  end
end

ActiveRecord::Base.class_eval do
  def self.subscribable?
    include? Subscribable
  end

  def subscribable?
    self.class.subscribable?
  end
end
