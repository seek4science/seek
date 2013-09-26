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

      def scales= scales, source=User.current_user
        scales = resolve_types(scales)

        remove = self.scales - scales
        add = scales - self.scales
        add.each do |scale|
          annotation = Annotation.new(
              :source => source,
              :annotatable => self,
              :attribute_name => "scale",
              :value => scale
          )
          annotation.save
        end
        remove.each do |scale|
          annotation = Annotation.for_annotatable(self.class.name,self.id).with_attribute_name("scale").select{|an| an.value == scale}.first
          annotation.destroy unless annotation.nil?
        end
      end

      def scales
        self.annotations_with_attribute("scale",true).collect{|an| an.value}.sort_by(&:pos)
      end

      private

      #handles scales passed as Id's, invalid or blank ids, or a single item
      def resolve_types scales
        scales = Array(scales).collect do |scale|
          if scale.is_a?(Numeric) || scale.is_a?(String)
            scale=Scale.find_by_id(scale)
          end
          scale
        end.compact
      end
    end

  end
end

ActiveRecord::Base.class_eval do
  include Seek::Scalable
end