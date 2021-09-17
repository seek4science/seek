module TemplatesHelper
  def template_attribute_details(template_attribute)
    type = template_attribute.sample_attribute_type.title

    if !template_attribute.sample_controlled_vocab.blank?
      type += ' - ' + link_to(template_attribute.sample_controlled_vocab.title, template_attribute.sample_controlled_vocab)
    end

    # unit = template_attribute.unit ? "( #{template_attribute.unit.symbol} )" : ''
    req = template_attribute.required? ? required_span : ''
    attribute_css = 'sample-attribute'
    # attribute_css << ' sample-attribute-title' if sample_type_attribute.is_title?
    content_tag :span, class: attribute_css do
      "#{h template_attribute.title} (#{type}) #{req}".html_safe
    end
  end

  def load_templates
    Template.all().order(:group, :group_order).map { |item|
      { title: item.title, type: item.level, group: item.group,
        organism: item.organism, template_id: item.id, level: item.level,
        description: item.description, attributes: 
        item.template_attributes.map { |attribute|
          { 
            attribute_type_id: attribute.sample_attribute_type_id,
            cv_id: attribute.sample_controlled_vocab_id,
            title: attribute.title,
            short_name: attribute.short_name,
            description: attribute.description,
            required: attribute.required,
            unit_id: attribute.unit_id 
          }
        }
      }
    }
  end
  
end
