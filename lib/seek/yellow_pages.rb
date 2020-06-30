module Seek #:nodoc:
  module YellowPages #:nodoc:
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

        has_many :activity_logs, as: :activity_loggable

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
          extend Seek::YellowPages::SingletonMethods
        end
        include Seek::YellowPages::InstanceMethods
        include Seek::Search::BackgroundReindexing
        include Seek::BioSchema::Support
        include Seek::Rdf::RdfGeneration
        include Seek::Rdf::ReactToAssociatedChange
        include HasCustomAvatar
      end

      def is_yellow_pages?
        include?(Seek::YellowPages::InstanceMethods)
      end
    end

    module SingletonMethods
      # defines that this is a user_creatable object type, and appears in the "New Object" gadget
      def user_creatable?
        false
      end
    end

    module InstanceMethods
    end
  end
end
