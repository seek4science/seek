module CustomMetadataHelper
  include SamplesHelper

  def custom_metadata_form_field_for_attribute(attribute, resource)
    element_class = "custom_metadata_attribute_#{attribute.sample_attribute_type.base_type.downcase}"
    element_name = "#{resource.class.name.underscore}[custom_metadata_attributes][data][#{attribute.title}]"

    if attribute.linked_custom_metadata? || attribute.linked_custom_metadata_multi?
      content_tag(:span, class: 'linked_custom_metdata') do
        folding_panel(attribute.label, false, id:attribute.title) do
            attribute_form_element(attribute, resource.custom_metadata.get_attribute_value(attribute.title), element_name, element_class)
        end
      end
    else
      content_tag(:label,attribute.label, class: attribute.required? ? 'required' : '') +
        attribute_form_element(attribute, resource.custom_metadata.get_attribute_value(attribute.title), element_name, element_class)
    end
  end

  def custom_metadata_attribute_description(description)
    html = '<p class="help-block">'
    html += '<small>'+description+'</small>'
    html += '</p>'
    html.html_safe
  end

    def render_custom_metadata_value(attribute, resource)

      if resource.custom_metadata.data[attribute.title].blank?
        return '' # Return an empty string if the custom metadata is blank.
      end

      content_tag(:div, class: 'custom_metadata') do
        if attribute.linked_custom_metadata? || attribute.linked_custom_metadata_multi?
          content_tag(:span, class: 'linked_custom_metdata_display') do
            folding_panel(attribute.label, true, id: attribute.title) do
              display_attribute(resource.custom_metadata, attribute, link: true)
            end
          end
        else
          label_tag("#{attribute.label}:") + display_attribute(resource.custom_metadata, attribute, link: true)
        end
      end
    end
end
