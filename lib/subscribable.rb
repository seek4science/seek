module Subscribable
  def self.included klass
    klass.class_eval do
      has_many :subscriptions, :as => :subscribable, :dependent => :destroy, :autosave => true
      before_create :set_default_subscriptions
      extend ClassMethods
    end
  end

  def current_users_subscription
    subscriptions.detect { |ss| ss.person == User.current_user.person }
  end

  def subscribed?
    !current_users_subscription.nil?
  end

  def subscribed= subscribed
    if subscribed
      subscribe
    else
      unsubscribe
    end
  end

  def subscribe
    subscriptions.build :person => User.current_user.person, :project => project unless subscribed?
  end

  def unsubscribe
    current_users_subscription.try(:destroy)
  end

  def send_immediate_subscriptions activity_log
    subscriptions.each do |subscription|
      if subscription.immediately? and subscribers_are_notified_of? activity_log.action
        SubMailer.deliver_send_immediate_subscription subscription.person, activity_log
      end
    end
  end

  def subscribers_are_notified_of? action
    self.class.subscribers_are_notified_of? action
  end

  def set_default_subscriptions
    Person.all.each do |person|
      if subscription = person.subscriptions.detect {|s| s.project = self.project}
        subscriptions.build :person => person, :project => self.project unless subscription.unsubscribed_resource_types.includes? self.class.name
      end
    end
  end

  module ClassMethods
    def subscribers_are_notified_of? action
      action != 'show' and action != 'download'
    end
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