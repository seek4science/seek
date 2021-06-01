module CustomMetadataHelper
  include SamplesHelper

  def custom_metadata_form_field_for_attribute(attribute, resource)
    base_type = attribute.sample_attribute_type.base_type
    clz = "custom_metadata_attribute_#{base_type.downcase}"
    element_name = "#{resource.class.name.underscore}[custom_metadata_attributes][data][#{attribute.title}]"
    value = resource.custom_metadata.try(:get_attribute_value,attribute.title)
    placeholder = "e.g. #{attribute.sample_attribute_type.placeholder}" unless attribute.sample_attribute_type.placeholder.blank?

    case base_type
    when Seek::Samples::BaseType::TEXT
      text_area_tag element_name, value, class: "form-control #{clz}"
    when Seek::Samples::BaseType::DATE_TIME
      content_tag :div, style:'position:relative' do
        text_field_tag element_name,value, data: { calendar: 'mixed' }, class: "calendar form-control #{clz}", placeholder: placeholder
      end
    when Seek::Samples::BaseType::DATE
      content_tag :div, style:'position:relative' do
        text_field_tag element_name, value, data: { calendar: true }, class: "calendar form-control #{clz}", placeholder: placeholder
      end
    when Seek::Samples::BaseType::BOOLEAN
      check_box_tag element_name, value, class: clz.to_s
    when Seek::Samples::BaseType::SEEK_DATA_FILE
      options = options_from_collection_for_select(DataFile.authorized_for(:view), :id,
                                                   :title, value.try(:[],'id'))
      select_tag(element_name, options, include_blank: !attribute.required?, class: "form-control #{clz}")
    when Seek::Samples::BaseType::CV
      controlled_vocab_form_field attribute, element_name, value
    else
      text_field_tag element_name, value, class: "form-control #{clz}", placeholder: placeholder
    end
  end
end
