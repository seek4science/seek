module SamplesHelper
  def sample_form_field_for_attribute(attribute)
    base_type = attribute.sample_attribute_type.base_type
    clz = "sample_attribute_#{base_type.downcase}"
    attribute_method_name = attribute.method_name
    case base_type
      when 'Text'
        text_area :sample, attribute_method_name, class: "form-control #{clz}"
      when 'DateTime'
        calendar_date_select :sample, attribute_method_name, time: :mixed, class: "form-control  #{clz}"
      when 'Date'
        calendar_date_select :sample, attribute_method_name, time: false, class: "form-control  #{clz}"
      when 'Boolean'
        check_box :sample, attribute_method_name, class: "#{clz}"
      when 'SeekStrain'
        grouped_collection_select :sample, attribute_method_name, Organism.all, :strains, :title, :id, :title, {}, class: "form-control #{clz}"
      when 'CV'
        terms = attribute.sample_controlled_vocab.sample_controlled_vocab_terms
        collection_select :sample, attribute_method_name, terms, :label, :label, { include_blank: !attribute.required? }, class: "form-control #{clz}"
      when 'SeekSample'
        terms = Sample.authorize_asset_collection(attribute.linked_sample_type.samples, :view)
        collection_select :sample, attribute_method_name, terms, :id, :title, { include_blank: !attribute.required? }, class: "form-control #{clz}"
      else
        text_field :sample, attribute_method_name, class: "form-control #{clz}"
    end
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
    value = sample.get_attribute(attribute.hash_key)
    unless value
      text_or_not_specified(value)
    else
      case attribute.sample_attribute_type.base_type
        when 'Date'
          Date.parse(value).strftime('%e %B %Y')
        when 'DateTime'
          DateTime.parse(value).strftime('%e %B %Y %H:%M:%S')
        when 'SeekStrain'
          seek_strain_attribute_display(value)
        when 'SeekSample'
          seek_sample_attribute_display(value)
        else
          default_attribute_display(attribute, options, sample, value)
      end
    end
  end

  def seek_sample_attribute_display(value)
    sample = Sample.find_by_id(value)
    if sample
      if sample.can_view?
        link_to sample.title, sample
      else
        content_tag :span, 'Hidden', class: 'none_text'
      end
    else
      content_tag :span, 'Not found', class: 'none_text'
    end
  end

  def default_attribute_display(attribute, options, sample, value)
    if options[:link] && attribute.is_title
      link_to(value, sample)
    else
      text_or_not_specified(value, auto_link: options[:link])
    end
  end

  def seek_strain_attribute_display(value)
    if value['title']
      link_to(value['title'], strain_path(value['id']))
    else
      content_tag(:span, value['id'], class: 'none_text')
    end
  end
end
