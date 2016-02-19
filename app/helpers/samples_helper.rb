module SamplesHelper
  def sample_form_field_for_attribute(attribute)
    base_type = attribute.sample_attribute_type.base_type
    clz="sample_attribute_#{base_type.downcase}"
    case base_type
      when 'Text'
        text_area :sample, attribute.accessor_name, :class=>"form-control #{clz}"
      when 'DateTime'
        calendar_date_select :sample, attribute.accessor_name, :time=>:mixed, :class=>"form-control  #{clz}"
      else
        text_field :sample, attribute.accessor_name, :class=>"form-control #{clz}"
    end
  end
end


