module Seek
  module Subscribable
    def self.included(klass)
      klass.class_eval do
        has_many :subscriptions, as: :subscribable, dependent: :destroy, autosave: true, before_add: proc { |item, sub| sub.subscribable = item } # ,:required_access_to_owner => false,
        after_create :set_subscription_job if self.subscribable?
        after_update :update_subscription_job_if_study_or_assay if self.subscribable?
        extend ClassMethods
      end
    end

    def current_users_subscription
      subscriptions.detect { |ss| ss.person == User.current_user.person }
    end

    def subscribed?(person = User.current_user.person)
      !subscriptions.detect { |sub| sub.person == person }.nil?
    end

    def subscribed=(subscribed)
      if subscribed
        subscribe
      else
        unsubscribe
      end
    end

    def subscribe(person = User.current_user.person)
      subscriptions << Subscription.new(person: person) unless subscribed?(person)
    end

    def unsubscribe(person = User.current_user.person)
      subscriptions.detect { |sub| sub.person == person }.try(:destroy)
    end

    def send_immediate_subscriptions(activity_log)
      if Seek::Config.email_enabled && subscribers_are_notified_of?(activity_log.action)
        subscriptions.each do |subscription|
          if !subscription.person.user.nil? && subscription.person.receive_notifications? && subscription.immediately? && can_view?(subscription.person.user)
            SubMailer.send_immediate_subscription(subscription.person, activity_log).deliver_now
          end
        end
      end
    end

    def subscribers_are_notified_of?(action)
      self.class.subscribers_are_notified_of? action
    end

    def set_default_subscriptions(projects)
      unless projects.empty?
        Person.includes(:project_subscriptions).each do |person|
          project_subscriptions = person.project_subscriptions
          project_subscriptions.each do |ps|
            next unless projects.include? ps.project
            subscriptions.create(person: person, project_subscription_id: ps.id) if !ps.unsubscribed_types.include?(self.class.name) && !self.subscribed?(person)
            # also build subscriptions for studies and assays associating with this investigation
            next unless self.is_a?(Investigation)
            (studies | assays).each do |item|
              item.subscriptions << Subscription.create(person: person, project_subscription_id: ps.id) unless item.subscribed?(person)
            end
          end
        end
      end
    end

    def remove_subscriptions(projects)
      unless projects.empty?
        project_subscription_ids = projects.collect(&:project_subscriptions).flatten.collect(&:id)
        subscriptions = Subscription.where(['subscribable_type=? AND subscribable_id=? AND project_subscription_id IN (?)', self.class.name, id, project_subscription_ids])
        # remove also subcriptions for studies and assays association with this investigation
        if self.is_a?(Investigation)
          study_ids = studies.collect(&:id)
          assay_ids = assays.collect(&:id)
          subscriptions |= Subscription.where(['subscribable_type=? AND subscribable_id IN (?) AND project_subscription_id IN (?)', 'Study', study_ids, project_subscription_ids])
          subscriptions |= Subscription.where(['subscribable_type=? AND subscribable_id IN (?) AND project_subscription_id IN (?)', 'Assay', assay_ids, project_subscription_ids])
        end
        subscriptions.each(&:destroy)
      end
    end

    def set_subscription_job
      projects = (Seek::Config.project_hierarchy_enabled) ? projects_and_descendants : self.projects
      SetSubscriptionsForItemJob.new(self, projects).queue_job
    end

    def update_subscription_job_if_study_or_assay
      if self.is_a?(Study) && self.investigation_id_changed?
        # update subscriptions for study
        old_investigation_id = investigation_id_was
        old_investigation = Investigation.find_by_id old_investigation_id
        projects_to_remove = old_investigation.nil? ? [] : old_investigation.projects
        projects_to_add = investigation.projects
        update_subscriptions_for self, projects_to_add, projects_to_remove
        # update subscriptions for assays associated with this study
        assays.each do |assay|
          update_subscriptions_for assay, projects_to_add, projects_to_remove
        end
      elsif self.is_a?(Assay) && self.study_id_changed?
        old_study_id = study_id_was
        old_study = Study.find_by_id old_study_id
        projects_to_remove = old_study.nil? ? [] : old_study.projects
        projects_to_add = study.projects
        update_subscriptions_for self, projects_to_add, projects_to_remove
      end
    end

    module ClassMethods
      def subscribers_are_notified_of?(action)
        action == 'create' || action == 'update'
      end
    end

    private

    def update_subscriptions_for(item, projects_to_add, projects_to_remove)
      SetSubscriptionsForItemJob.new(item, projects_to_add).queue_job
      RemoveSubscriptionsForItemJob.new(item, projects_to_remove).queue_job
    end
  end
end

ActiveRecord::Base.class_eval do
  def self.subscribable?
    include? Seek::Subscribable
  end

  def subscribable?
    self.class.subscribable?
  end
end
