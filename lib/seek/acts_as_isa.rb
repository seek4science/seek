

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
        acts_as_authorized
        acts_as_uniquely_identifiable
        acts_as_discussable
        has_extended_custom_metadata

        title_trimmer

        

        validates :title, presence: true
        validates :title, length: { maximum: 255 }
        validates :description, length: { maximum: 65_535 }

        grouped_pagination

        include Seek::ActsAsISA::Relationships::Associations

        include Seek::ActsAsISA::InstanceMethods
        include Seek::Stats::ActivityCounts
        include Seek::Search::CommonFields, Seek::Search::BackgroundReindexing
        include Seek::Subscribable
        include Seek::Rdf::RdfGeneration
        include Seek::Taggable
        include Seek::ResearchObjects::Packaging
        has_many :programmes, ->{ distinct }, through: :projects

        extend Seek::ActsAsISA::SingletonMethods
      end

      def is_isa?
        include?(Seek::ActsAsISA::InstanceMethods)
      end
    end

    module SingletonMethods
      def user_creatable?
        feature_enabled?
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
