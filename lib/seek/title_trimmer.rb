# A common pattern to trim titles before the are saved. This is used in most assets
module Seek
  module TitleTrimmer
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def title_trimmer
        before_save :trim_title
        include Seek::TitleTrimmer::InstanceMethods
      end
    end

    module InstanceMethods
      def trim_title
        self.title = title.strip if has_attribute?(:title) && title
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Seek::TitleTrimmer
end
