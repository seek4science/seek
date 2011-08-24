module Acts
  module Scalable
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    def is_scalable?
      self.class.is_scalable?

    end

    module ClassMethods
      def acts_as_scalable

        after_save :set_scaler
        has_many :scales,:through=>:scalings,:source=>:scale
        has_many :scalings,:as => :scalable, :dependent => :destroy, :include => :scale,:before_add => proc {|item, scaling| scaling.scalable = item}

        class_eval do
          extend Acts::Scalable::SingletonMethods
        end
        include Acts::Scalable::InstanceMethods
      end

      def is_scalable?
          include? Acts::Scalable::InstanceMethods
      end


    end
    module SingletonMethods

    end
    module InstanceMethods
      def set_scaler
        #user cannot scale the item when not logging in
        unless User.current_user.nil?
          scalings.each do |s|
          s.person = User.current_user.person
          s.save!
          end
        end

      end
    end


  end



end

ActiveRecord::Base.class_eval do
  include Acts::Scalable
end
