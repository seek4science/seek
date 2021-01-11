module WorkflowsHelper
  def port_types(port)
    return content_tag(:span, 'n/a', class: 'none_text') if port.type.nil?

    if port.type.is_a?(Array) && port.type.length > 1
      type_tag = content_tag(:ul) do
        port.type.map do |type|
          content_tag(:li, type)
        end
      end
    else
      type = port.type.is_a?(Array) ? port.type.first : port.type
      type_tag = content_tag(:span, type)
    end

    if port.optional?
      type_tag + content_tag(:span, ' (Optional)', class: 'subtle')
    else
      type_tag
    end
  end

  def maturity_badge(level)
    content_tag(:span,
                t("maturity_level.#{level}"),
                class: "maturity-level label #{level == :released ? 'label-success' : 'label-warning'}")
  end
end
