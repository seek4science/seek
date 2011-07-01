module SendImmediateSubscription

  def self.included klass
    klass.class_eval do
      has_many :specific_subscriptions, :as => :subscribable, :dependent => :destroy, :autosave => true
    end
  end

  def current_users_subscription
    specific_subscriptions.detect { |ss| ss.person == User.current_user.person }
  end

  def current_user_subscribed
    !current_users_subscription.nil?
  end

  def current_user_subscribed= subscribed
    if subscribed
      specific_subscriptions.build :person => User.current_user.person, :project => project unless current_users_subscription
    else
      current_users_subscription.try(:destroy)
    end
  end

  def subscription_type
    current_users_subscription.try(:subscription_type)
  end

  def subscription_type= type
    unless current_users_subscription.nil?
      current_users_subscription.subscription_type = type
     else
      specific_subscriptions.build :person => User.current_user.person, :project => project
    end
  end

  def send_immediate_subscription activity_log
    if self.current_user_subscribed and self.subscription_type==Subscription::IMMEDIATELY
      SubMailer.deliver_send_immediate_subscription activity_log
    else
      p "resource is not subscribed for immediate changes!!"
    end
  end

end