module CustomMetadataHelper
  include SamplesHelper

  def custom_metadata_form_field_for_attribute(attribute, resource)
    element_class = "custom_metadata_attribute_#{attribute.sample_attribute_type.base_type.downcase}"
    element_name = "#{resource.class.name.underscore}[custom_metadata_attributes][data][#{attribute.title}]"

    attribute_form_element(attribute, resource.custom_metadata, element_name, element_class)
  end
end

def custom_metadata_attribute_description(description)
  html = '<p class="help-block">'
  html += '<small>'+description+'</small>'
  html += '</p>'
  html.html_safe
end
