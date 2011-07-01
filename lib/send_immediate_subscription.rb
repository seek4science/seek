module SendImmediateSubscription

  def self.include klass
    klass.class_eval do
      #after_create :set_subscribable_id_for_new_object
      has_many :specific_subscriptions,:as=>:subscribable,:dependent=>:destroy
    end

  end


  def set_subscribable_id_for_new_object
      sub = User.current_user.person.specific_subscriptions.detect{|ss|ss.subscribable_type==self.class.to_s and ss.subscribable_id.nil?}
      unless sub.nil?
        sub.subscribable_id = self.id
        sub.save!
      end

  end
  def current_users_subscription

      User.current_user.person.specific_subscriptions.detect{|ss|ss.subscribable==self}
  end

  def current_user_subscribed
      !current_users_subscription.nil?

  end

  def current_user_subscribed= subscribed
      if subscribed
       new_sub = nil
       new_sub = SpecificSubscription.new(:person_id=>User.current_user.person.id,:project_id=>self.try(:project).try(:id),:subscribable=>self) if current_users_subscription.nil?
       User.current_user.person.specific_subscriptions << new_sub if new_sub
      else
        current_users_subscription.try(:destroy)
      end
  end

  def subscription_type
      current_users_subscription.try(:subscription_type)
  end

  def subscription_type=   type

     unless  current_users_subscription.nil?
     current_users_subscription.subscription_type = type
     #current_users_subscription.save!
     else
      new_sub = SpecificSubscription.new(:person_id=>User.current_user.person.id,:project_id=>self.try(:project).try(:id),:subscribable=>self,:subscription_type=>type)
      User.current_user.person.specific_subscriptions << new_sub
     end
  end

  def send_immediate_subscription activity_log_id
     model = self.class.to_s
     p "##############"
     p model

     set_subscribable_id_for_new_object unless self.new_record?

     activity_log = ActivityLog.find activity_log_id

     if  self.current_user_subscribed and self.subscription_type==Subscription::IMMEDIATELY
      SubMailer.deliver_send_immediate_subscription activity_log
     else
       p "resource is not subscribed for immediate changes!!"
     end
  end

end