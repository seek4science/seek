module Seek #:nodoc:
  module ActsAsHavingMiscLinks #:nodoc:
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    def have_misc_links?
      self.class.have_misc_links?
    end

    module ClassMethods
      def acts_as_having_misc_links
        has_many :misc_links, -> { where(AssetLink.misc_link.where_values_hash) }, class_name: 'AssetLink', as: :asset, dependent: :destroy, inverse_of: :asset
        accepts_nested_attributes_for :misc_links, allow_destroy: true

        class_eval do
          extend Seek::ActsAsHavingMiscLinks::SingletonMethods
        end
        include Seek::ActsAsHavingMiscLinks::InstanceMethods
      end

      def have_misc_links?
        include?(Seek::ActsAsHavingMiscLinks::InstanceMethods)
      end
    end

    module SingletonMethods
    end

    module InstanceMethods
    end
  end
end
