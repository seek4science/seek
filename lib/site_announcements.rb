module SiteAnnouncements

  module Acts
    def self.included(mod)
      mod.extend(ClassMethods)
    end
    
    module ClassMethods
      def acts_as_notifiee(options = {}, &extension)
        
        has_one :notifiee_info,:dependent=>:destroy,:as=>:notifiee
        
        before_save :check_for_notifiee_info
        
        extend SiteAnnouncements::Acts::SingletonMethods
        include SiteAnnouncements::Acts::InstanceMethods
      end
    end
    
    module SingletonMethods
      
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
end

ActiveRecord::Base.send(:include,SiteAnnouncements::Acts)
