require 'title_trimmer'
require 'grouped_pagination'

module Seek
  module ActsAsISA
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    def is_isa?
      self.class.is_isa?
    end

    module ClassMethods
      def acts_as_isa
        acts_as_favouritable
        acts_as_scalable
        acts_as_authorized
        acts_as_uniquely_identifiable

        title_trimmer

        attr_accessor :create_from_asset

        scope :default_order, order('title')
        validates :title, presence: true

        grouped_pagination

        include Seek::ActsAsISA::Relationships::Associations

        include Seek::ActsAsISA::InstanceMethods
        include Seek::Stats::ActivityCounts
        include Seek::Search::CommonFields, Seek::Search::BackgroundReindexing
        include Seek::Subscribable
        include Seek::ResearchObjects::Packaging
        include Seek::ProjectHierarchies::ItemsProjectsExtension if Seek::Config.project_hierarchy_enabled
        include ProgrammeCompat

        extend Seek::ActsAsISA::SingletonMethods

      end

      def is_isa?
        include?(Seek::ActsAsISA::InstanceMethods)
      end
    end

    module SingletonMethods
      # defines that this is a user_creatable object type, and appears in the "New Object" gadget
      def user_creatable?
        true
      end
      def can_create?
        User.logged_in_and_member?
      end
    end

    module InstanceMethods
      include Seek::ActsAsISA::Relationships::InstanceMethods
    end
  end
end

ActiveRecord::Base.class_eval do
  include Seek::ActsAsISA
end
