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
      includes(:notifiee_info).where(notifiee_infos: { receive_notifications: true })
    end
  end

  module InstanceMethods

    def check_for_notifiee_info
      if (self.notifiee_info.nil?)
        n=NotifieeInfo.new
        self.notifiee_info=n
      end
    end

    def receive_notifications?
      self.notifiee_info.try(:receive_notifications?)
    end

  end
end
