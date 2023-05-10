FactoryBot.define do
  # TemplateAttribute
  factory(:template_attribute) do
    sequence(:title) { |n| "Template attribute #{n}" }
    association :template, factory: :template
  end
  
  factory(:apples_controlled_vocab_template_attribute, parent: :template_attribute) do
    sequence(:title) { |n| "apples controlled vocab template attribute #{n}" }
    after(:build) do |type|
      type.sample_controlled_vocab = FactoryBot.build(:apples_sample_controlled_vocab)
      type.sample_attribute_type = FactoryBot.create(:controlled_vocab_attribute_type)
    end
  end
end
