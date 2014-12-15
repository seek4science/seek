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
        scope :default_order, order("title")


        title_trimmer

        attr_accessor :create_from_asset

        validates :title,:presence => true

        has_many :favourites,
                 :as        => :resource,
                 :dependent => :destroy

        grouped_pagination

        acts_as_uniquely_identifiable

        include Seek::Stats::ActivityCounts

        include Seek::Search::CommonFields

        class_eval do
          extend Seek::ActsAsISA::SingletonMethods
        end
        include Seek::ActsAsISA::InstanceMethods
        include BackgroundReindexing
        include Subscribable
        include Seek::ProjectHierarchies::ItemsProjectsExtension if Seek::Config.project_hierarchy_enabled
      end

      def is_isa?
        include?(Seek::ActsAsISA::InstanceMethods)
      end
    end

    module SingletonMethods
      #defines that this is a user_creatable object type, and appears in the "New Object" gadget
      def user_creatable?
        true
      end
    end

    module InstanceMethods

      def related_people
        peeps = [contributor.try(:person)]
        peeps << person_responsible if self.respond_to?(:person_responsible)
        peeps.uniq.compact
      end

    end
  end
end



ActiveRecord::Base.class_eval do
  include Seek::ActsAsISA
end
