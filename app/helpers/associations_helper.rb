module AssociationsHelper
  def associations_list(id, template_name, existing, options = {})
    content_tag(:div, :id => id, 'data-role' => 'seek-associations-list', 'data-template-name' => template_name) do
      content_tag(:ul, '', class: 'associations-list') +
        content_tag(:span, options[:empty_text] || 'No items', class: 'none_text no-item-text') +
        content_tag(:script, existing.html_safe, :type => 'application/json', 'data-role' => 'seek-existing-associations')
    end
  end

  def association_selector(association_list_id, button_text, modal_title, &_block)
    modal_id = 'modal' + button_text.parameterize.underscore.camelize
    button_link_to(button_text, 'add', '#', 'data-toggle' => 'modal', 'data-target' => "##{modal_id}") +
      modal(class: 'new-association-modal', id: modal_id, size: 'xl') do
        modal_header(modal_title) +
          modal_body do
            yield
          end +
          modal_footer do
            confirm_association_button(button_text, association_list_id)
          end
      end
  end

  def filterable_association_select(filter_url, options = {}, &_block)
    content_tag(:div, class: 'form-group') do
      content_tag(:input, '', class: 'form-control association-filter',
                              type: 'text', placeholder: 'Type to filter...',
                              autocomplete: 'off', 'data-filter-url' => filter_url)
    end +
      content_tag(:div, class: 'list-group association-candidate-list',
                  data: { role: 'seek-association-candidate-list',
                          multiple: options.delete(:multiple) || 'false' }) do
        yield
      end
  end

  def confirm_association_button(text, associations_list_id)
    content_tag(:button, text, class: 'btn btn-primary',
                               'data-role' => 'seek-confirm-association-button',
                               'data-associations-list-id' => associations_list_id)
  end
end
