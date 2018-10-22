module HasSettings
  extend ActiveSupport::Concern

  included do
    has_many :settings, class_name: 'Settings', as: :target, dependent: :destroy do
      def [](*args, &block)
        fetch_value(*args, &block)
      end

      def []=(*args, &block)
        set_value(*args, &block)
      end
    end
  end
end
