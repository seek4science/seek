module AssociationsHelper

  def associations_list(id, template_name, existing, options = {})
    content_tag(:div, :id => id, 'data-role' => 'seek-associations-list', 'data-template-name' => template_name) do
      content_tag(:ul, '', :class => 'associations-list') +
      content_tag(:span, options[:empty_text] || 'No items', :class => 'none_text no-item-text') +
      content_tag(:script, existing.html_safe, :type => 'application/json', 'data-role' => 'seek-existing-associations')
    end
  end

  def confirm_association_button(text, associations_list_id)
    content_tag(:button, text, :class => 'btn btn-primary',
                'data-role' => 'seek-confirm-association-button',
                'data-associations-list-id' => associations_list_id)
  end

end