

module Acts #:nodoc:
  module Yellow_Pages #:nodoc:
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    def is_yellow_pages?
      self.class.is_yellow_pages?
    end

    module ClassMethods
      def acts_as_yellow_pages
        acts_as_favouritable

        default_scope :order => "#{self.table_name}.name"

        validates_presence_of :name

        #TODO: refactor to remove :name entirely
        alias_attribute :title, :name

        has_many :avatars,
                 :as        => :owner,
                 :dependent => :destroy

        has_many :activity_logs, :as => :activity_loggable

        validates_associated :avatars

        belongs_to :avatar

        acts_as_uniquely_identifiable

        class_eval do
          extend Acts::Yellow_Pages::SingletonMethods
        end
        include Acts::Yellow_Pages::InstanceMethods

      end

      def is_yellow_pages?
        include?(Acts::Yellow_Pages::InstanceMethods)
      end
    end

    module SingletonMethods
      #defines that this is a user_creatable object type, and appears in the "New Object" gadget
      def user_creatable?
        false
      end
    end

    module InstanceMethods
      # "false" returned by this helper method won't mean that no avatars are uploaded for this yellow page model;
      # it rather means that no avatar (other than default placeholder) was selected for the yellow page model
      def avatar_selected?
        return !self.avatar_id.nil?
      end
    end
  end

end


ActiveRecord::Base.class_eval do
  include Acts::Yellow_Pages
end