FactoryBot.define do
  # TemplateAttribute
  factory(:template_attribute) do
    sequence(:title) { |n| "Template attribute #{n}" }
    association :template, factory: :template
    isa_tag_id { nil }
  end

  factory(:apples_controlled_vocab_template_attribute, parent: :template_attribute) do
    sequence(:title) { |n| "apples controlled vocab template attribute #{n}" }
    after(:build) do |type|
      type.sample_controlled_vocab = FactoryBot.build(:apples_sample_controlled_vocab)
      type.sample_attribute_type = FactoryBot.create(:controlled_vocab_attribute_type)
    end
	end

	factory(:boolean_template_attribute, parent: :template_attribute) do
		sequence(:title) { |n| "boolean attribute #{n}" }
		association :template, factory: :template
		sample_attribute_type { FactoryBot.create(:boolean_sample_attribute_type) }
	end

	factory(:sop_template_attribute, parent: :template_attribute) do
		sequence(:title) { |n| "SOP attribute #{n}" }
		association :template, factory: :template
		sample_attribute_type { FactoryBot.create(:sop_sample_attribute_type) }
	end

	factory(:strain_template_attribute, parent: :template_attribute) do
		sequence(:title) { |n| "Strain attribute #{n}" }
		association :template, factory: :template
		sample_attribute_type { FactoryBot.create(:strain_sample_attribute_type) }
	end

	factory(:data_file_template_attribute, parent: :template_attribute) do
		sequence(:title) { |n| "Datafile attribute #{n}" }
		association :template, factory: :template
		sample_attribute_type { FactoryBot.create(:data_file_sample_attribute_type) }
	end

	factory(:float_template_attribute, parent: :template_attribute) do
		sequence(:title) { |n| "Float attribute #{n}" }
		association :template, factory: :template
		sample_attribute_type { FactoryBot.create(:float_sample_attribute_type) }
	end

	factory(:datetime_template_attribute, parent: :template_attribute) do
		sequence(:title) { |n| "Datetime attribute #{n}" }
		association :template, factory: :template
		sample_attribute_type { FactoryBot.create(:datetime_sample_attribute_type) }
	end
end
