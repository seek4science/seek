module AssociationsHelper

  def associations_list(id, template_name, existing, options = {})
    empty_text = options.delete(:empty_text) || 'No items'
    options.reverse_merge!(id: id,
                           class: 'box_editing_inner',
                           blank_field: true,
                           'data-role' => 'seek-associations-list',
                           'data-template-name' => template_name)

    content_tag(:div, options) do
      content = content_tag(:ul, '', class: 'associations-list related_asset_list') +
          content_tag(:span, empty_text, class: 'none_text no-item-text') +
          content_tag(:script, existing.html_safe, :type => 'application/json', 'data-role' => 'seek-existing-associations')
      # Add an empty hidden field to allow removal of all items
      # This ensures that the parameter is always sent, even when nothing is selected.
      # It adds a "" as the first item in the array. So if items 1,2, and 3 are selected the
      # value of the parameter will be ["","1","2","3"]. This is compatible with the rails
      # association association_ids= methods, which reject 'blank' values automatically.
      if options['data-field-name'] && options[:blank_field]
        hidden_field_tag("#{options['data-field-name']}[]", nil, id: nil) + content
      else
        content
      end
    end
  end

  def associations_list_group(id, grouping_attribute, existing, _options = {})
    content_tag(:div, :id => id, 'data-role' => 'seek-associations-list-group', 'data-grouping-attribute' => grouping_attribute) do
      content_tag(:script, existing.html_safe, :type => 'application/json', 'data-role' => 'seek-existing-associations') +
        content_tag(:div) do
          yield
        end
    end
  end

  def association_selector(association_list_id, button_text, modal_title, modal_options = {}, &_block)
    modal_id = 'modal' + button_text.parameterize.underscore.camelize
    modal_options.reverse_merge!(id: modal_id, size: 'xl', 'data-role' => 'seek-association-form',
                                 'data-associations-list-id' => association_list_id)
    button_link_to(button_text, 'add', '#', 'data-toggle' => 'modal', 'data-target' => "##{modal_id}") +
      modal(modal_options) do
        modal_header(modal_title) +
          modal_body do
            yield
          end +
          modal_footer do
            confirm_association_button(button_text, 'data-dismiss' => 'modal')
          end
      end
  end

  def association_select_filter
    text_field_tag(:filter, nil, class: 'form-control', 'data-role' => 'seek-association-filter-field',
                   placeholder: 'Type to filter...',
                   autocomplete: 'off')
  end

  def association_select_results(options = {}, &_block)
    content_tag(:div, class: 'list-group association-candidate-list',
                data: { role: 'seek-association-candidate-list',
                        multiple: options.delete(:multiple) || 'false' }) do
      yield if block_given?
    end
  end

  def filterable_association_select(filter_url, options = {}, &_block)
    options.reverse_merge!(multiple: false)
    content_tag(:div, class: 'form-group', 'data-role' => 'seek-association-filter-group', 'data-filter-url' => filter_url) do
      association_select_filter +
      association_select_results(options = {}) { yield }
    end
  end

  def confirm_association_button(text, options = {})
    options.reverse_merge!(class: 'btn btn-primary',
                           'data-role' => 'seek-association-confirm-button')
    content_tag(:button, text, options)
  end

  def associations_json_from_relationship(related_items, extra_data = {})
    related_items.map do |item|
      { title: item.title, id: item.id }.reverse_merge(extra_data)
    end.to_json
  end

  def associations_json_from_assay_assets(assay_assets, extra_data = {})
    assay_assets.map do |aa|
      hash = { title: aa.asset.title, id: aa.asset_id,
               assay: { id: aa.assay_id, title: aa.assay.title },
               direction: { value: aa.direction, text: direction_name(aa.direction) }
      }.reverse_merge(extra_data)
      if aa.relationship_type
        hash[:relationship_type] = { value: aa.relationship_type.id,
                                     text: aa.relationship_type.title }
      end

      hash
    end.to_json
  end

  def associations_json_from_scales(object, scales, extra_data = {})
    scales.map do |scale|
      scale_params = object.fetch_additional_scale_info(scale.id)
      if scale_params.any?
        scale_params.map do |info|
          { id: scale.id, title: scale.title,
            extraParams: info.merge(stringified: info.to_json.to_s) }.reverse_merge(extra_data)
        end
      else
        { id: scale.id, title: scale.title }.reverse_merge(extra_data)
      end
    end.flatten.to_json
  end



  def associations_json_from_params(model, association_params)
    association_params.map do |association|
      item = model.find(association[:id])
      hash = { title: item.title, id: item.id,
               direction: { value: association[:direction],
                            text: direction_name(association[:direction]) }
      }
      unless association[:relationship_type].blank?
        hash.merge!(relationship_type: { value: association[:relationship_type],
                                         text: RelationshipType.find_by_id(association[:relationship_type]).try(:title) })
      end

      hash
    end.to_json
  end

  def associations_json_from_assay_organisms(assay_organisms, extra_data = {})
    assay_organisms.map do |o|
      ao = {
          organism_id:  o.organism.id,
          organism_title:  escape_javascript(o.organism.title)
      }
      if o.strain
        ao[:strain_info] = o.strain.info
        ao[:strain_id] = o.strain.id
      end
      ao[:culture_growth] = o.culture_growth_type.title if o.culture_growth_type
      if o.tissue_and_cell_type
        ao[:tissue_and_cell_type_id] = o.tissue_and_cell_type_id
        ao[:tissue_and_cell_type_title] = escape_javascript(o.tissue_and_cell_type.title)
      end

      ao.reverse_merge(extra_data)
    end.flatten.to_json
  end

  def associations_json_from_workflow_to_data_files(workflow_data_files)
    workflow_data_files.map do |wfdf|
      hash = { title: wfdf.data_file.title, id: wfdf.data_file.id}
      if wfdf.workflow_data_file_relationship
        hash[:workflow_data_file_relationship]= { value: wfdf.workflow_data_file_relationship.id, text: wfdf.workflow_data_file_relationship.title }
      end
      hash
    end.to_json
  end

  def associations_json_from_data_file_to_workflows(workflow_data_files)
    workflow_data_files.map do |wfdf|
      hash = { title: wfdf.workflow.title, id: wfdf.workflow.id}
      if wfdf.workflow_data_file_relationship
        hash[:workflow_data_file_relationship]= { value: wfdf.workflow_data_file_relationship.id, text: wfdf.workflow_data_file_relationship.title }
      end
      hash
    end.to_json
  end

  def associations_json_from_assay_human_diseases(assay_human_diseases, extra_data = {})
    assay_human_diseases.map do |d|
      ad = {
        human_disease_id:    d.human_disease.id,
        human_disease_title: escape_javascript(d.human_disease.title)
      }

      ad.reverse_merge(extra_data)
    end.flatten.to_json
  end
end
