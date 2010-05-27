module Seek
  module UniquelyIdentifiable
    
    def self.included(mod)
      mod.extend(ClassMethods)
    end
    
    module ClassMethods
      def acts_as_uniquely_identifiable
        before_validation :check_uuid        
        validates_presence_of :uuid
        
        include Seek::UniquelyIdentifiable::InstanceMethods
      end     
    end
    
    module SingletonMethods
    end
    
    module InstanceMethods
      def check_uuid
        if self.uuid.nil?
          self.uuid = UUIDTools::UUID.random_create.to_s
        end
      end
    end
    
  end
end

ActiveRecord::Base.class_eval do
  include Seek::UniquelyIdentifiable
end