module Acts #:nodoc:
  module Favouritable #:nodoc:
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    def is_favouritable?
      self.class.is_favouritable?
    end

    module ClassMethods
      def acts_as_favouritable

        has_many :favourites,
                 :as        => :resource,
                 :dependent => :destroy

        class_eval do
          extend Acts::Favouritable::SingletonMethods
        end
        include Acts::Favouritable::InstanceMethods

      end

      def is_favouritable?
        include?(Acts::Favouritable::InstanceMethods)
      end


    end


    module SingletonMethods

    end

    module InstanceMethods
    end
  end

end


ActiveRecord::Base.class_eval do
  include Acts::Favouritable
end