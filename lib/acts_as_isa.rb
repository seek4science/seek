require 'title_trimmer'
require 'grouped_pagination'


module Acts #:nodoc:
  module Isa #:nodoc:
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    def is_isa?
      self.class.is_isa?
    end

    module ClassMethods
      def acts_as_isa
        acts_as_favouritable

        scope :default_order, order("title")

        title_trimmer

        attr_accessor :create_from_asset

        validates_presence_of :title

        has_many :favourites,
                 :as        => :resource,
                 :dependent => :destroy

        has_many :activity_logs, :as => :activity_loggable

        grouped_pagination

        acts_as_uniquely_identifiable


        class_eval do
          extend Acts::Isa::SingletonMethods
        end
        include Acts::Isa::InstanceMethods
        include BackgroundReindexing
        include Subscribable

      end

      def is_isa?
        include?(Acts::Isa::InstanceMethods)
      end
    end

    module SingletonMethods
      #defines that this is a user_creatable object type, and appears in the "New Object" gadget
      def user_creatable?
        true
      end
    end

    module InstanceMethods
    end
  end

end


ActiveRecord::Base.class_eval do
  include Acts::Isa
end
