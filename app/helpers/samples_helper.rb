module SamplesHelper
  def sample_form_field_for_attribute(attribute)
    base_type = attribute.sample_attribute_type.base_type
    clz="sample_attribute_#{base_type.downcase}"
    case base_type
      when 'Text'
        text_area :sample, attribute.method_name, :class=>"form-control #{clz}"
      when 'DateTime'
        calendar_date_select :sample, attribute.method_name, :time=>:mixed, :class=>"form-control  #{clz}"
      when 'Date'
        calendar_date_select :sample, attribute.method_name, :time=>false, :class=>"form-control  #{clz}"
      when 'Boolean'
        check_box :sample, attribute.method_name,:class=>"#{clz}"
      when 'SeekStrain'
        grouped_collection_select :sample, attribute.method_name, Organism.all, :strains, :title, :id, :title, :class=>"#{clz}"
      else
        text_field :sample, attribute.method_name, :class=>"form-control #{clz}"
    end
  end

  def authorised_samples(projects = nil)
    authorised_assets(Sample, projects)
  end

  def sample_attribute_title_and_unit(attribute)
    title = attribute.title
    if (unit = attribute.unit) && !unit.dimensionless?
      title = title + " ( #{unit.to_s} )"
    end
    title
  end

  def display_attribute(sample, attribute, options = {})
    value = sample.get_attribute(attribute.hash_key)
    if value.nil?
      content_tag(:span, 'Not specified', class: 'none_text')
    else
      case attribute.sample_attribute_type.base_type
        when 'Date'
          Date.parse(value).strftime("%e %B %Y")
        when 'DateTime'
          DateTime.parse(value).strftime("%e %B %Y %H:%M:%S")
        when 'SeekStrain'
          if value['title']
            link_to(value['title'], strain_path(value['id']))
          else
            content_tag(:span, value['id'], class: 'none_text')
          end
        else
          if options[:link] && attribute.is_title
            link_to(value, sample)
          else
            text_or_not_specified(value, auto_link: options[:link])
          end
      end
    end
  end

end


