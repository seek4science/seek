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
        
        default_scope :order => "#{self.table_name}.updated_at DESC"

        title_trimmer

        validates_presence_of :title

        has_many :favourites,
                 :as        => :resource,
                 :dependent => :destroy

        grouped_pagination :default_page => Seek::Config.default_page(self.name.underscore.pluralize)

        acts_as_uniquely_identifiable


        class_eval do
          extend Acts::Isa::SingletonMethods
        end
        include Acts::Isa::InstanceMethods

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
