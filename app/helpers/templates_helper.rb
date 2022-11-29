module TemplatesHelper
  def template_attribute_details(template_attribute)
    type = template_attribute.sample_attribute_type.title

    unless template_attribute.sample_controlled_vocab.blank?
      type += ' - ' + link_to(template_attribute.sample_controlled_vocab.title,
                              template_attribute.sample_controlled_vocab)
    end

    req = template_attribute.required? ? required_span : ''
    attribute_css = 'sample-attribute'
    content_tag :span, class: attribute_css do
      "#{h template_attribute.title} (#{type}) #{req}".html_safe
    end
  end

  def load_templates
    privilege = Seek::Permissions::Translator.translate('view')
    Template.order(:group, :group_order).select { |t| t.can_perform?(privilege) }.map do |item|
      { title: item.title, group: item.group, level: item.level,
        organism: item.organism, template_id: item.id,
        description: item.description, group_order: item.group_order,
        attributes: item.template_attributes.order(:pos).map { |a| map_template_attributes(a) } }
    end
  end

  def template_attribute_details_table(attributes)
    head = content_tag :thead do
      content_tag :tr do
        "<th>Name</th><th>Type</th><th>Description</th><th>PID #{sample_attribute_pid_help_icon}</th><th>Unit</th>".html_safe
      end
    end

    body = content_tag :tbody do
      attributes.collect do |attr|
        req = attr.required? ? required_span.html_safe : ''
        unit = attr.unit ? attr.unit.symbol : "<span class='none_text'>-</span>".html_safe
        description = attr.description.present? ? attr.description : "<span class='none_text'>Not specified</span>".html_safe
        pid = attr.pid.present? ? attr.pid : "<span class='none_text'>-</span>".html_safe

        type = template_attribute_type_link(attr)

        content_tag :tr do
          concat content_tag :td, (h(attr.title) + req).html_safe
          concat content_tag :td, type.html_safe
          concat content_tag :td, description
          concat content_tag :td, pid
          concat content_tag :td, unit
        end
      end.join.html_safe
    end

    content_tag :table, head.concat(body), class: 'table table-responsive table-hover'
  end

  private

  def template_attribute_type_link(template_attribute)
    type = template_attribute.sample_attribute_type.title

    if template_attribute.sample_attribute_type.controlled_vocab?
      type += ' - ' + link_to(template_attribute.sample_controlled_vocab.title,
                              template_attribute.sample_controlled_vocab)
    end
    type
  end

  def map_template_attributes(attribute)
    {
      attribute_type_id: attribute.sample_attribute_type_id,
      data_type: SampleAttributeType.find(attribute.sample_attribute_type_id)&.title,
      cv_id: attribute.sample_controlled_vocab_id,
      title: attribute.title,
      is_title: attribute.is_title,
      short_name: attribute.short_name,
      description: attribute.description,
      pid: attribute.pid,
      required: attribute.required,
      unit_id: attribute.unit_id,
      pos: attribute.pos,
      isa_tag_id: attribute.isa_tag_id
    }
  end
end
