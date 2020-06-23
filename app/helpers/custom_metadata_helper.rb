module CustomMetadataHelper
  include SamplesHelper

  def custom_metadata_form_field_for_attribute(attribute, form)
    base_type = attribute.sample_attribute_type.base_type
    clz = "custom_metadata_attribute_#{base_type.downcase}"
    attribute_method_name = attribute.method_name
    placeholder = "e.g. #{attribute.sample_attribute_type.placeholder}" unless attribute.sample_attribute_type.placeholder.blank?

    case base_type
    when Seek::Samples::BaseType::TEXT
      form.text_area attribute_method_name, class: "form-control #{clz}"
    when Seek::Samples::BaseType::DATE_TIME
      content_tag :div, style:'position:relative' do
        form.text_field attribute_method_name, data: { calendar: 'mixed' }, class: "calendar form-control #{clz}", placeholder: placeholder
      end
    when Seek::Samples::BaseType::DATE
      content_tag :div, style:'position:relative' do
        form.text_field attribute_method_name, data: { calendar: true }, class: "calendar form-control #{clz}", placeholder: placeholder
      end
    when Seek::Samples::BaseType::BOOLEAN
      form.check_box attribute_method_name, class: clz.to_s
    else
      form.text_field attribute_method_name, class: "form-control #{clz}", placeholder: placeholder
    end
  end
end
