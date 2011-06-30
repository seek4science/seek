module SendImmediateSubscription
  def current_users_subscription
      User.current_user.person.specific_subscriptions.detect{|ss|ss.subscribable==self}
  end

  def current_user_subscribed
      current_users_subscription
  end

  def current_user_subscribed= subscribed
      if subscribed
        SpecificSubscription.create!(:person_id=>User.current_user.person.id,:project_id=>self.try(:project_id),:subscribable=>self)  unless current_users_subscription
      else
        current_users_subscription.try(:destroy)
      end
  end

  def subscription_type
      current_users_subscription.subscription_type
  end

  def subscription_type=   type
      current_users_subscription.subscription_type = type
  end

  def send_immediate_subscription activity_log_id
     model = self.class.to_s
     p "##############"
     p model


     activity_log = ActivityLog.find activity_log_id

     if  self.current_user_subscribed and self.subscription_type==Subscription::IMMEDIATELY
      SubMailer.deliver_send_immediate_subscription activity_log
     else
       p "resource is not subscribed for immediate changes!!"
     end
  end

end