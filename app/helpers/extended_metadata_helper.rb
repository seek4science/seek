module ExtendedMetadataHelper
  include SamplesHelper

  def extended_metadata_form_field_for_attribute(attribute, resource, parent_resource=nil)
    element_class = "extended_metadata_attribute_#{attribute.sample_attribute_type.base_type.downcase}"

    if parent_resource
      element_name = "#{parent_resource}[#{resource.class.name.underscore}][extended_metadata_attributes][data][#{attribute.title}]"
    else
      element_name = "#{resource.class.name.underscore}[extended_metadata_attributes][data][#{attribute.title}]"
    end

    if attribute.linked_extended_metadata? || attribute.linked_extended_metadata_multi?
      content_tag(:span, class: 'linked_extended_metdata') do
        folding_panel(attribute.label, false, id:attribute.title) do
            attribute_form_element(attribute, resource.extended_metadata.get_attribute_value(attribute.title), element_name, element_class)
        end
      end
    else
      content_tag(:label,attribute.label, class: attribute.required? ? 'required' : '') +
        attribute_form_element(attribute, resource.extended_metadata.get_attribute_value(attribute.title), element_name, element_class)
    end
  end

  def extended_metadata_attribute_description(description)
    html = '<p class="help-block">'
    html += '<small>'+description+'</small>'
    html += '</p>'
    html.html_safe
  end

    def render_extended_metadata_value(attribute, resource)

      if resource.extended_metadata.data[attribute.title].blank?
        return '' # Return an empty string if the extended metadata is blank.
      end

      content_tag(:div, class: 'extended_metadata') do
        if attribute.linked_extended_metadata? || attribute.linked_extended_metadata_multi?
          content_tag(:span, class: 'linked_extended_metdata_display') do
            folding_panel(attribute.label, false, id: attribute.title) do
              display_attribute(resource.extended_metadata, attribute, link: true)
            end
          end
        else
          label_tag("#{attribute.label} : ") + " " + display_attribute(resource.extended_metadata, attribute, link: true)
        end
      end
    end
end
