module TemplatesHelper
  def template_attribute_details(template_attribute)
    type = template_attribute.sample_attribute_type.title

    if !template_attribute.sample_controlled_vocab.blank?
      type += ' - ' + link_to(template_attribute.sample_controlled_vocab.title, template_attribute.sample_controlled_vocab)
    end

    req = template_attribute.required? ? required_span : ''
    attribute_css = 'sample-attribute'
    content_tag :span, class: attribute_css do
      "#{h template_attribute.title} (#{type}) #{req}".html_safe
    end
  end

  def load_templates
    privilege = Seek::Permissions::Translator.translate("view")
    Template.select{|t| t.can_perform?(privilege)}.map { |item|
      { title: item.title, group: item.group, level: item.level,
        organism: item.organism, template_id: item.id,
        description: item.description,
        attributes: item.template_attributes.order(:pos).map { |a| map_template_attributes(a) }
      }
    }
  end

  private 

  def map_template_attributes(attribute)
    { 
      attribute_type_id: attribute.sample_attribute_type_id,
      data_type: SampleAttributeType.find(attribute.sample_attribute_type_id)&.title,
      cv_id: attribute.sample_controlled_vocab_id,
      title: attribute.title,
      is_title: attribute.is_title,
      short_name: attribute.short_name,
      description: attribute.description,
      iri: attribute.iri,
      required: attribute.required,
      unit_id: attribute.unit_id,
      pos: attribute.pos,
      isa_tag_id: attribute.isa_tag_id
    }
  end
  
end
