module Seek #:nodoc:
  module ActsAsDiscussable #:nodoc:
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    def is_discussable?
      self.class.is_discussable?
    end

    module ClassMethods
      def acts_as_discussable
        has_many :discussion_links, -> { where(AssetLink.discussion.where_values_hash) }, class_name: 'AssetLink', as: :asset, dependent: :destroy, inverse_of: :asset
        accepts_nested_attributes_for :discussion_links, allow_destroy:true

        class_eval do
          extend Seek::ActsAsDiscussable::SingletonMethods
        end
        include Seek::ActsAsDiscussable::InstanceMethods
      end

      def is_discussable?
        include?(Seek::ActsAsDiscussable::InstanceMethods)
      end
    end

    module SingletonMethods
    end

    module InstanceMethods
    end
  end
end
