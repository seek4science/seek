module SamplesHelper
  def sample_form_field_for_attribute(attribute,form)
    base_type = attribute.sample_attribute_type.base_type
    clz="sample_attribute_#{base_type.downcase}"
    case base_type
      when 'DateTime'
        form.calendar_date_select attribute.accessor_name, :time=>:mixed, :class=>"form-control  #{clz}"
      else
        form.text_field attribute.accessor_name, :class=>"form-control #{clz}"
    end
  end
end


