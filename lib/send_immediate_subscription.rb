module SendImmediateSubscription
  def current_users_subscription
      User.current_user.person.specific_subscriptions.detect{|ss|ss.subscribable==self}
  end

  def current_user_subscribed
      current_users_subscription
  end

  def current_user_subscribed= subscribed
      if subscribed
        SpecificSubscription.create!(:person_id=>User.current_user.person.id,:subscribable=>self)  unless current_users_subscription
      else
        current_users_subscription.try(:destroy)
      end
  end

  def send_immediate_subscription activity_log_id
     model = self.class.to_s
     p "##############"
     p model


     activity_log = ActivityLog.find activity_log_id

     if  self.current_user_subscribed
      SubMailer.deliver_send_specific_subscription activity_log
     else
       p "resource is not subscribed!!"
     end
  end

end