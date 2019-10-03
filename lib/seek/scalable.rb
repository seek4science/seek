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
        has_annotation_type(:scale, method_name: 'scale_values')
        has_many :scales, -> { order(:pos) }, through: :scale_annotations, source: :value, source_type: 'Scale'
        has_filter scale: Seek::Filtering::Filter.new(
            value_field: 'scales.id',
            label_field: 'scales.title',
            joins: [:scales]
        )

        has_annotation_type(:additional_scale_info)

        attr_reader :scales_changed
        after_save :remove_additional_scale_info, if: ->{ scales_changed }
      end
    end

    module InstanceMethods
      def scales=(vals, source = User.current_user)
        scale_values = Array(vals).map { |scale| scale.is_a?(Scale) ? scale : Scale.find_by_id(scale) }.compact.uniq
        self.scale_annotations = scale_values.map do |scale|
          self.scale_annotations.build(source: source, value: scale)
        end
        @scales_changed = true

        scales
      end

      def scale_extra_params=(params_array)
        additional_scale_info_annotations.destroy_all

        params_array.each do |json|
          next if json.blank?
          data = JSON.parse(json)
          attach_additional_scale_info(data['scale_id'], param: data['param'], unit: data['unit'])
        end
      end
    end

    module WithParamsInstanceMethods
      def attach_additional_scale_info(scale_id, other_info = {}, source = User.current_user)
        other_info[:scale_id] = scale_id.to_s
        self.additional_scale_info_annotations.build(source: source, value: other_info.to_json)
      end

      def fetch_additional_scale_info(scale_id)
        self.additional_scale_info_annotations.select do |an|
          json = JSON.parse(an.value.text)
          json['scale_id'] == scale_id.to_s
        end.collect do |an|
          json = JSON.parse(an.value.text)
          json['param'] = h(json['param'])
          json['unit'] = h(json['unit'])
          json
        end
      end

      def remove_additional_scale_info
        ids = self.scales.reload.map { |s| s.id.to_s }
        self.additional_scale_info_annotations.to_a.reject do |an|
          json = JSON.parse(an.value.text)
          ids.include?(json['scale_id'].to_s)
        end.each(&:destroy)
      end
    end
  end
end
