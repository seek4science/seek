# TemplateAttribute
Factory.define(:template_attribute) do |f|
  f.sequence(:title) { |n| "Template attribute #{n}" }
  f.association :template, factory: :template
end

Factory.define(:apples_controlled_vocab_template_attribute, parent: :template_attribute) do |f|
  f.sequence(:title) { |n| "apples controlled vocab template attribute #{n}" }
  f.after_build do |type|
    type.sample_controlled_vocab = Factory.build(:apples_sample_controlled_vocab)
    type.sample_attribute_type = Factory(:controlled_vocab_attribute_type)
  end
end