module SamplesHelper
  def sample_form_field_for_attribute(attribute, resource)
    element_class = "sample_attribute_#{attribute.sample_attribute_type.base_type.downcase}"
    element_name = "sample[data][#{attribute.title}]"

    attribute_form_element(attribute, resource, element_name, element_class)
  end

  def controlled_vocab_form_field(sample_controlled_vocab, element_name, values, limit=1)
    if sample_controlled_vocab.sample_controlled_vocab_terms.count < Seek::Config.cv_dropdown_limit
      options = options_from_collection_for_select(
        sample_controlled_vocab.sample_controlled_vocab_terms.sort_by(&:label),
        :label, :label,
        values
      )
      select_tag element_name,
                 options,                 
                 class: "form-control",
                 include_blank: ""
    else
      scv_id = sample_controlled_vocab.id
      existing_objects = Array(values).collect do |value|
        Struct.new(:id, :name).new(value, value)
      end
      objects_input(element_name, existing_objects,
                    typeahead: { query_url: typeahead_sample_controlled_vocabs_path + "?query=%QUERY&scv_id=#{scv_id}", 
                    handlebars_template: 'typeahead/controlled_vocab_term' }, 
                    limit: limit)
    end
  end

  def sample_multi_form_field(attribute, element_name, value)  
    existing_objects = []
    str = Struct.new(:id, :name)
    value.each {|v| existing_objects << str.new(v[:id], v[:title]) if v} if value
    objects_input(element_name, existing_objects,
                  typeahead: { query_url: typeahead_samples_path + "?query=%QUERY&linked_sample_type_id=#{attribute.linked_sample_type.id}", 
                  handlebars_template: 'typeahead/controlled_vocab_term' }, 
                  limit: 5)
  end

  def authorised_samples(projects = nil)
    authorised_assets(Sample, projects)
  end

  def sample_attribute_title_and_unit(attribute)
    title = attribute.title
    if (unit = attribute.unit) && !unit.dimensionless?
      title += " ( #{unit} )"
    end
    title
  end

  def display_attribute(sample, attribute, options = {})
    value = sample.get_attribute_value(attribute)
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
      when Seek::Samples::BaseType::CV
        seek_cv_attribute_display(value, attribute)
      else
        default_attribute_display(attribute, options, sample, value)
      end
    end
  end

  def seek_cv_attribute_display(value, attribute)
    term = attribute.sample_controlled_vocab.sample_controlled_vocab_terms.where(label:value).last
    content = value
    if term && term.iri
      content << " (#{term.iri}) "
    end
    content
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

  def default_attribute_display(attribute, options, sample, value)
    resolution = attribute.resolve (value)
    if (resolution != nil)
      link_to(value, resolution, target: :_blank)
    else if options[:link] && attribute.is_title
        link_to(value, sample)
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
    if (sample.sample_type.can_view?(user))
      link_to sample.sample_type.title,sample.sample_type
    else
      link_to sample.sample_type.title,sample_type_path(sample.sample_type, referring_sample_id:sample.id)
    end
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
    link = "https://www.ebi.ac.uk/ols/ontologies/#{ols_id}"
    link_to(link,link,target: :_blank)
  end

  def ols_root_term_link(ols_id, term_uri)
    ols_link = "https://www.ebi.ac.uk/ols/ontologies/#{ols_id}/terms?iri=#{term_uri}"
    link_to(term_uri, ols_link, target: :_blank)
  end

  private

  def attribute_form_element(attribute, resource, element_name, element_class )
    value = resource.get_attribute_value(attribute.title)
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
    when Seek::Samples::BaseType::CV
      controlled_vocab_form_field attribute.sample_controlled_vocab, element_name, value
    when Seek::Samples::BaseType::SEEK_SAMPLE
      terms = attribute.linked_sample_type.samples.authorized_for('view').to_a
      options = options_from_collection_for_select(terms, :id, :title, value.try(:[], 'id'))
      select_tag element_name, options,
                 include_blank: !attribute.required?, class: "form-control #{element_class}"
    when Seek::Samples::BaseType::SEEK_SAMPLE_MULTI
      sample_multi_form_field attribute, element_name, value
    else
      text_field_tag element_name, value, class: "form-control #{element_class}", placeholder: placeholder
    end
  end

end
