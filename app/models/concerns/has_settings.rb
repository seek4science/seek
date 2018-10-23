module HasSettings
  extend ActiveSupport::Concern

  included do
    has_many :settings, class_name: 'Settings', as: :target, dependent: :destroy do
      def [](*args, &block)
        get(*args, &block)
      end

      def []=(*args, &block)
        set(*args, &block)
      end
    end
  end
end
