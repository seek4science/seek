module Seek
  module Scalable
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods

      def acts_as_scalable
        acts_as_annotatable :name_field=>:title
        include Seek::Scalable::InstanceMethods
      end
    end

    module InstanceMethods
      def scales= scales
        #TODO: look into reusing Taggable and tag_with
        Array(scales).each do |scale|
          annotation = Annotation.new(
              :source=>User.current_user,
              :annotatable=>self,
              :attribute_name=>"scale",
              :value=>scale
          )
          annotation.save!
        end
      end

      def scales
        self.annotations_with_attribute("scale",true).collect{|an| an.value}.sort_by(&:pos)
      end
    end

  end
end

ActiveRecord::Base.class_eval do
  include Seek::Scalable
end