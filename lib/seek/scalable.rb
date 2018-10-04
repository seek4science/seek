module Seek
  module Scalable
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def acts_as_scalable
        acts_as_annotatable name_field: :title
        include Seek::Scalable::InstanceMethods
        include Seek::Scalable::WithParamsInstanceMethods
      end
    end

    module InstanceMethods
      def scales=(scales, source = User.current_user)
        # handles scales passed as Id's, invalid or blank ids, or a single item
        scales = Array(scales).map { |scale| scale.is_a?(Scale) ? scale : Scale.find_by_id(scale) }.compact

        remove = self.scales - scales
        add = scales - self.scales

        add.each do |scale|
          self.annotations.build(
            source: source,
            attribute_name: 'scale',
            value: scale
          )
        end

        scale_annotations = annotations_with_attribute('scale')
        remove.each do |scale|
          annotation = scale_annotations.find { |an| an.value == scale }
          annotation.destroy unless annotation.nil?
          remove_additional_scale_info(scale.id)
        end
      end

      def scales
        annotations_with_attribute('scale', true).collect(&:value).sort_by(&:pos)
      end

      def scale_extra_params=(params_array)
        params_array.each do |json|
          data = JSON.parse(json)
          attach_additional_scale_info data['scale_id'], param: data['param'], unit: data['unit']
        end
      end
    end

    module WithParamsInstanceMethods
      def attach_additional_scale_info(scale_id, other_info = {}, source = User.current_user)
        other_info[:scale_id] = scale_id.to_s

        self.annotations.build(
          source: source,
          attribute_name: 'additional_scale_info',
          value: other_info.to_json
        )
      end

      def fetch_additional_scale_info(scale_id)
        annotations_with_attribute('additional_scale_info', true).select do |an|
          json = JSON.parse(an.value.text)
          json['scale_id'] == scale_id.to_s
        end.collect do |an|
          json = JSON.parse(an.value.text)
          json['param'] = h(json['param'])
          json['unit'] = h(json['unit'])
          json
        end
      end

      def remove_additional_scale_info(scale_id)
        annotations_with_attribute('additional_scale_info', true).select do |an|
          json = JSON.parse(an.value.text)
          json['scale_id'] == scale_id.to_s
        end.each(&:destroy)
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Seek::Scalable
end
