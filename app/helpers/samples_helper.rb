module SamplesHelper
  def sample_form_field_for_attribute(attribute, resource)
    element_class = "sample_attribute_#{attribute.sample_attribute_type.base_type.downcase}"
    element_name = "sample[data][#{attribute.title}]"

    attribute_form_element(attribute, resource.get_attribute_value(attribute.title), element_name, element_class)
  end

  def controlled_vocab_form_field(sample_controlled_vocab, element_name, values, allow_new, limit = 1)

    scv_id = sample_controlled_vocab.id
    object_struct = Struct.new(:id, :title)
    existing_objects = Array(values).collect do |value|
      object_struct.new(value, value)
    end

    typeahead = { handlebars_template: 'typeahead/controlled_vocab_term' }

    if sample_controlled_vocab.sample_controlled_vocab_terms.count < Seek::Config.cv_dropdown_limit
      values = sample_controlled_vocab.sample_controlled_vocab_terms.collect do |term|
        {
          id: term.label,
          text: term.label,
          iri: term.iri
        }
      end
      typeahead[:values] = values
    else
      typeahead[:query_url] = typeahead_sample_controlled_vocabs_path + "?scv_id=#{scv_id}"
    end

    objects_input(element_name, existing_objects,
                  typeahead: typeahead,
                  limit: limit,
                  allow_new: allow_new,
                  class: 'form-control')

  end

  def controlled_vocab_list_form_field(sample_controlled_vocab, element_name, values, allow_new)
    controlled_vocab_form_field(sample_controlled_vocab, element_name, values, allow_new, nil)
  end

  def linked_extended_metadata_multi_form_field(attribute, value, element_name, element_class)
    render partial: 'extended_metadata/fancy_linked_extended_metadata_multi_attribute_fields',
           locals: { value: value, attribute: attribute, element_name: element_name, element_class: element_class, collapsed: false }
  end

  def linked_extended_metadata_form_field(attribute, value, element_name, element_class,depth)
    html = ''

    attribute.linked_extended_metadata_type.extended_metadata_attributes.each do |attr|
      attr_element_name = "#{element_name}[#{attr.title}]"
      html += '<div class="form-group"><label>'+attr.label+'</label>'
      html +=  required_span if attr.required?
      v = value ? value[attr.title] : nil
      if attr.linked_extended_metadata?
        html += '<div class="form-group linked_extended_metdata_'+(depth.even? ? 'even' : 'odd')+'">'
        html +=  attribute_form_element(attr, v, attr_element_name, element_class,depth+1)
        html += '</div>'
      else
        html +=  attribute_form_element(attr, v, attr_element_name, element_class)
      end

      unless attr.description.nil?
        html += extended_metadata_attribute_description(attr.description)
      end
      html += '</div>'
    end

    html.html_safe
  end

  def sample_form_field(attribute, element_name, value, limit = 1)

    existing_objects = []
    str = Struct.new(:id, :title)
    if value
      value = [value] unless value.is_a?(Array)
      value.compact.each do |v|
        id = v[:id]
        next if id.blank? # Skip value if there is no ID

        title = v[:title]
        title = '<em>Hidden</em>' unless Sample.find(id).can_view?
        existing_objects << str.new(id, title)
      end
    end

    typeahead = { query_url: typeahead_samples_path + "?linked_sample_type_id=#{attribute.linked_sample_type.id}",
                  handlebars_template: 'typeahead/controlled_vocab_term' }
    objects_input(element_name, existing_objects,
                  typeahead: typeahead,
                  limit: limit,
                  class: 'form-control')
  end

  def sample_multi_form_field(attribute, element_name, value)
    sample_form_field(attribute, element_name, value, nil)
  end

  def authorised_samples(projects = nil)
    authorised_assets(Sample, projects)
  end

  def sample_attribute_display_title(attribute)
    title = attribute.title
    if (unit = attribute.unit) && !unit.dimensionless?
      title += " ( #{unit} )"
    end
    unless attribute.pid.blank?
      title += content_tag(:small, 'data-tooltip'=>attribute.pid) do
        " [ "+attribute.short_pid+ " ]"
      end.html_safe
    end
    title.html_safe
  end

  def display_attribute(resource, attribute, options = {})
    value = resource.get_attribute_value(attribute)
    display_attribute_value(value, attribute, options.merge(resource: resource))
  end

  def display_attribute_value(value, attribute, options = {})
    if value.blank?
      text_or_not_specified(value)
    else
      case attribute.sample_attribute_type.base_type
      when Seek::Samples::BaseType::DATE
        Date.parse(value).strftime('%e %B %Y')
      when Seek::Samples::BaseType::DATE_TIME
        DateTime.parse(value).strftime('%e %B %Y %H:%M:%S')
      when Seek::Samples::BaseType::SEEK_STRAIN
        seek_strain_attribute_display(value)
      when Seek::Samples::BaseType::SEEK_SAMPLE
        seek_sample_attribute_display(value)
      when Seek::Samples::BaseType::SEEK_SAMPLE_MULTI
        seek_sample_attribute_display(value)
      when Seek::Samples::BaseType::SEEK_DATA_FILE
        seek_data_file_attribute_display(value)
      when Seek::Samples::BaseType::SEEK_SOP
        seek_sop_attribute_display(value)
      when Seek::Samples::BaseType::CV
        seek_cv_attribute_display(value, attribute)
      when Seek::Samples::BaseType::CV_LIST
        value.map do |v|
          seek_cv_attribute_display(v, attribute)
        end.join(', ').html_safe
      when Seek::Samples::BaseType::LINKED_EXTENDED_METADATA
        linked_extended_metadata_attribute_display(value, attribute)
      when Seek::Samples::BaseType::LINKED_EXTENDED_METADATA_MULTI
        linked_extended_metadata_multi_attribute_display(value, attribute)
      else
        default_attribute_display(value, attribute, options)
      end
    end
  end

  def select_cv_source_ontology(sample_controlled_vocab)
    ontology_choices = Ebi::OlsClient.ontology_choices
    local_options = ontology_choices.collect do |choice|
      { id: choice[1], text: choice[0]}
    end
    existing = []
    if sample_controlled_vocab.source_ontology
      label = ontology_choices.select{|choice| choice[1] == sample_controlled_vocab.source_ontology}.first.try(:[],0)
      existing = [OpenStruct.new({id: sample_controlled_vocab.source_ontology, title: label })]
    end
    placeholder = 'Select or Search, or leave blank for No Ontology'
    objects_input 'sample_controlled_vocab[source_ontology]', existing, {typeahead: {values:local_options},
                                                                         placeholder: placeholder,
                                                                         multiple: false}
  end

  def seek_cv_attribute_display(value, attribute)
    term = attribute.sample_controlled_vocab.sample_controlled_vocab_terms.where(label: value).last
    if term && term.iri.present?
      iri_content = term.iri.match?(/^https?:\/\//) ? link_to(term.iri, term.iri, target: '_blank') : term.iri
      label_tag = content_tag(:label, term.label, class: 'term-label')
      iri_tag = content_tag(:label, iri_content, class: 'term-iri badge')
      "#{label_tag}#{iri_tag}".html_safe
    elsif term.nil? && attribute.allow_cv_free_text?
      value
    else
      term&.label
    end
  end

  def linked_extended_metadata_attribute_display(value, attribute)
    html = ''
    html += '<ul>'
    attribute.linked_extended_metadata_type.extended_metadata_attributes.each do |attr|
      v = value ? value[attr.title.to_s] : nil
      html += '<li>'
      if attr.linked_extended_metadata? || attr.linked_extended_metadata_multi?
        html += content_tag(:span, class: 'linked_extended_metdata_display') do
          folding_panel(attr.label, true, id:attr.title) do
            display_attribute_value(v, attr)
          end
        end
      else
        html += '<label>'+attr.title+'</label>'+' : '
        html += display_attribute_value(v, attr)
      end
      html += '</li>'
    end
    html += '</ul>'
    html.html_safe
  end

  def linked_extended_metadata_multi_attribute_display(values, attribute)
    html = ''
    values.each do |value|
      html += linked_extended_metadata_attribute_display(value, attribute)
    end
    html.html_safe
  end

  def seek_sample_attribute_display(value)
    if value.kind_of?(Array)
      value.map {|v| seek_resource_attribute_display(Sample,v)} .join(", ").html_safe
    else
      seek_resource_attribute_display(Sample,value)
    end
  end

  def seek_data_file_attribute_display(value)
    seek_resource_attribute_display(DataFile,value)
  end

  def seek_sop_attribute_display(value)
    seek_resource_attribute_display(Sop,value)
  end

  def seek_resource_attribute_display(clz, value)
    item = clz.find_by_id(value['id'])
    if item
      if item.can_view?
        link_to item.title, item
      else
        content_tag :span, 'Hidden', class: 'none_text'
      end
    else
      content_tag :span, value['title'], class: 'none_text'
    end
  end

  def default_attribute_display(value, attribute, options)
    resolution = attribute.resolve(value)
    if resolution
      link_to(value, resolution, target: :_blank)
    else
      if options[:link] && options[:resource] && attribute.is_title
        link_to(value, options[:resource])
      else
        text_or_not_specified(value, auto_link: options[:link])
      end
    end
  end

  def seek_strain_attribute_display(value)
    if value && value['id']
      if value['title']
        link_to(value['title'], strain_path(value['id']))
      else
        content_tag(:span, value['id'], class: 'none_text')
      end
    else
      content_tag(:span, 'Not specified', class: 'none_text')
    end
  end

  # link for the sample type for the provided sample. Handles a referring_sample_id if required
  def sample_type_link(sample, user=User.current_user)
    return nil if Seek::Config.isa_json_compliance_enabled && !sample.sample_type.template_id.nil?

    link_to sample.sample_type.title, sample.sample_type if sample.sample_type.can_view?(user)
  end

  def sample_type_list_item_attribute(attribute, sample)
    value = sample_type_link(sample)
    html = content_tag(:p,class:'list_item_attribute') do
      content_tag(:b) do
        "#{attribute}: "
      end + value
    end
    html.html_safe
  end

  def ols_ontology_link(ols_id)
    link = "#{Ebi::OlsClient::ROOT_URL}/ontologies/#{ols_id}"
    link_to(link,link,target: :_blank)
  end

  def ols_root_term_link(ols_id, term_uris)
    term_uris.split(',').collect(&:strip).collect do |uri|
      ols_link = "#{Ebi::OlsClient::ROOT_URL}/ontologies/#{ols_id}/terms?iri=#{uri}"
      link_to(uri, ols_link, target: :_blank)
    end.join(', ').html_safe
  end

  def get_extra_info(sample)
    studies = sample.sample_type.studies.authorized_for('view')
    assays = sample.sample_type.assays.authorized_for('view')
    {
      project_ids: sample.project_ids.join(','),
      project_names: sample.projects.map { |p| link_to(p.title, p, target: :_blank) }.join(',').html_safe,
      study_ids: studies.map(&:id).join(','),
      study_names: studies.map { |s| link_to(s.title, s, target: :_blank) }.join(',').html_safe,
      assay_ids: assays.map(&:id).join(','),
      assay_names: assays.map { |a| link_to(a.title, a, target: :_blank) }.join(',').html_safe
    }
  end

  # whether to attempt to show the extract samples button,
  # the final check of whether there is a sample type will be done asynchronously
  def attempt_to_show_extract_samples_button?(asset, display_asset)
    return false unless SampleType.any? && asset.can_manage? && asset.content_blob&.is_extractable_spreadsheet?
    return false unless asset.extracted_samples.empty? && (display_asset.version == asset.version)
    return false if asset.sample_extraction_task&.in_progress?

    !(asset.sample_extraction_task&.success? && Seek::Samples::Extractor.new(asset).fetch.present?)

  rescue Seek::Samples::FetchException
    true #allows to try again, the previous cached results may be broken
  end

  def show_sample_extraction_status?(data_file)
    # there is permission and a task
    return false unless data_file.can_manage? && data_file.sample_extraction_task&.persisted?
    # persistence isn't currently running or already taken place
    return !( data_file.sample_persistence_task&.success? || data_file.sample_persistence_task&.in_progress? )
  end

  private

  def attribute_form_element(attribute, value, element_name, element_class, depth=1)
    placeholder = "e.g. #{attribute.sample_attribute_type.placeholder}" unless attribute.sample_attribute_type.placeholder.blank?

    case attribute.sample_attribute_type.base_type
    when Seek::Samples::BaseType::TEXT
      text_area_tag element_name, value, class: "form-control #{element_class}"
    when Seek::Samples::BaseType::DATE_TIME
      content_tag :div, style: 'position:relative' do
        text_field_tag element_name, value, data: { calendar: 'mixed' }, class: "calendar form-control #{element_class}", placeholder: placeholder
      end
    when Seek::Samples::BaseType::DATE
      content_tag :div, style: 'position:relative' do
        text_field_tag element_name, value, data: { calendar: true }, class: "calendar form-control #{element_class}", placeholder: placeholder
      end
    when Seek::Samples::BaseType::BOOLEAN
      content_tag :div, class: 'form-check' do
        unless attribute.required?
          concat(text_field_tag(element_name, '', class: 'form-check-input', type: :radio, checked: value != true && value != false))
          concat(label_tag(nil, "Unset", class: 'form-check-label', style: 'padding-left:0.25em;padding-right:1em;'))
        end

        concat(text_field_tag(element_name, 'true', class: 'form-check-input', type: :radio, checked: value == true))
        concat(label_tag(nil, "true", class: 'form-check-label', style: 'padding-left:0.25em;padding-right:1em;'))

        concat(text_field_tag(element_name, 'false', class: 'form-check-input', type: :radio, checked: value == false))
        concat(label_tag(nil, "false", class: 'form-check-label', style: 'padding-left:0.25em;padding-right:1em;'))
      end
    when Seek::Samples::BaseType::SEEK_STRAIN
      options = option_groups_from_collection_for_select(Organism.all, :strains,
                                                         :title, :id,
                                                         :title, value.try(:[], 'id'))
      select_tag(element_name, options, include_blank: !attribute.required?, class: "form-control #{element_class}")
    when Seek::Samples::BaseType::SEEK_DATA_FILE
      options = options_from_collection_for_select(DataFile.authorized_for(:view), :id,
                                                   :title, value.try(:[], 'id'))
      select_tag(element_name, options, include_blank: !attribute.required?, class: "form-control #{element_class}")
    when Seek::Samples::BaseType::SEEK_SOP
      options = options_from_collection_for_select(Sop.authorized_for(:view), :id,
                                                   :title, value.try(:[], 'id'))
      select_tag(element_name, options, include_blank: !attribute.required?, class: "form-control #{element_class}")
    when Seek::Samples::BaseType::CV
      controlled_vocab_form_field attribute.sample_controlled_vocab, element_name, value, attribute.allow_cv_free_text?
    when Seek::Samples::BaseType::CV_LIST
      controlled_vocab_list_form_field attribute.sample_controlled_vocab, element_name, value, attribute.allow_cv_free_text?
    when Seek::Samples::BaseType::SEEK_SAMPLE
      sample_form_field attribute, element_name, value
    when Seek::Samples::BaseType::SEEK_SAMPLE_MULTI
      sample_multi_form_field attribute, element_name, value
    when Seek::Samples::BaseType::LINKED_EXTENDED_METADATA
      linked_extended_metadata_form_field attribute, value, element_name, element_class,depth
    when Seek::Samples::BaseType::LINKED_EXTENDED_METADATA_MULTI
      linked_extended_metadata_multi_form_field attribute, value, element_name, element_class
    else
      text_field_tag element_name, value, class: "form-control #{element_class}", placeholder: placeholder
    end
  end

end
