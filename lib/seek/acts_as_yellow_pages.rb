

module Seek #:nodoc:
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

        validates :title, presence: true

        has_many :avatars,
                 as: :owner,
                 dependent: :destroy

        has_many :activity_logs, as: :activity_loggable

        validates :avatar, associated: true

        belongs_to :avatar

        acts_as_uniquely_identifiable

        # grouped_pagination :pages=>("A".."Z").to_a #shouldn't need "Other" tab for people, project, institution
        # load the configuration for the pagination
        grouped_pagination pages: ('A'..'Z').to_a

        include Seek::Search::CommonFields

        searchable(auto_index: false) do
          text :locations do
            if self.respond_to?(:country)
              country
            elsif self.respond_to?(:locations)
              locations
            end
          end
        end if Seek::Config.solr_enabled

        class_eval do
          extend Seek::Yellow_Pages::SingletonMethods
        end
        include Seek::Yellow_Pages::InstanceMethods
        include Seek::Search::BackgroundReindexing
      end

      def is_yellow_pages?
        include?(Seek::Yellow_Pages::InstanceMethods)
      end
    end

    module SingletonMethods
      # defines that this is a user_creatable object type, and appears in the "New Object" gadget
      def user_creatable?
        false
      end
    end

    module InstanceMethods
      # "false" returned by this helper method won't mean that no avatars are uploaded for this yellow page model;
      # it rather means that no avatar (other than default placeholder) was selected for the yellow page model
      def avatar_selected?
        !avatar_id.nil?
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Seek::Yellow_Pages
end
