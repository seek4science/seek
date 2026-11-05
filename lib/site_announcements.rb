module SiteAnnouncements
  def self.included(mod)
    mod.extend(ClassMethods)
  end

  module ClassMethods
    def acts_as_notifiee(options = {}, &extension)

      has_one :notifiee_info,:dependent=>:destroy,:as=>:notifiee

      before_save :check_for_notifiee_info

      extend SiteAnnouncements::SingletonMethods
      include SiteAnnouncements::InstanceMethods
    end
  end

  module SingletonMethods
    def notifiable
      joins(:user).includes(:notifiee_info).where(notifiee_infos: { receive_notifications: true })
    end
  end

  module InstanceMethods

    def check_for_notifiee_info
      if (self.notifiee_info.nil?)
        n=NotifieeInfo.new
        self.notifiee_info=n
      end
    end

    # The receive_notifications flag defaults to true for every profile, including those created by someone else
    # that have no registered user, so it doesn't on its own mean the person opted in.
    def receive_notifications?
      registered? && self.notifiee_info.try(:receive_notifications?)
    end

  end
end
