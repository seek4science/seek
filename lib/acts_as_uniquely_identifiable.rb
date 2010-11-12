require 'uuidtools'
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
    
    module InstanceMethods
      
      def regenerate_uuid        
        self.uuid = "#{UUIDTools::UUID.random_create.to_s}"       
      end
      
      def uuid
        unless changed.include?("uuid")
          regenerate_uuid if super.nil?
        end
        super
      end
      
      def check_uuid
        if uuid.nil?
          regenerate_uuid
        end
      end
    end
    
  end
end

ActiveRecord::Base.class_eval do
  include Seek::UniquelyIdentifiable
end
