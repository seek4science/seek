
module Seek
  module UniquelyIdentifiable
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def acts_as_uniquely_identifiable
        before_validation :check_uuid
        validates_presence_of :uuid

        include Seek::UniquelyIdentifiable::InstanceMethods
      end
    end

    module InstanceMethods
      def regenerate_uuid
        self.uuid = UUID.generate
      end

      def uuid
        regenerate_uuid unless changed.include?('uuid') || !super.nil?
        super
      end

      def check_uuid
        regenerate_uuid if uuid.nil?
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Seek::UniquelyIdentifiable
end
