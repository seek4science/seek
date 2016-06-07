module SampleTypesHelper
  def sample_attribute_details(sample_type_attribute)
    type = sample_type_attribute.sample_attribute_type.title
    unit = sample_type_attribute.unit ? "( #{ sample_type_attribute. unit.symbol } )" : ''
    req = sample_type_attribute.required? ? required_span : ''

    "#{h sample_type_attribute.title} (#{type}) #{unit} #{req}".html_safe
  end
end
