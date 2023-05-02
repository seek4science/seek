FactoryBot.define do
  # SampleAttribute
  factory(:sample_attribute) do
    sequence(:title) { |n| "Sample attribute #{n}" }
    association :sample_type, factory: :sample_type
  end
  
  # a string that must contain 'xxx'
  factory(:simple_string_sample_attribute, parent: :sample_attribute) do
    sample_attribute_type factory: :xxx_string_sample_attribute_type
    required { true }
  end
  
  factory(:any_string_sample_attribute, parent: :sample_attribute) do
    sample_attribute_type factory: :string_sample_attribute_type
    required { true }
  end
  
  factory(:data_file_sample_attribute, parent: :sample_attribute) do
    sample_attribute_type factory: :data_file_sample_attribute_type
    required { true }
  end
  
  factory(:sample_sample_attribute, parent: :sample_attribute) do
    sequence(:title) { |n| "sample attribute #{n}" }
    linked_sample_type factory: :simple_sample_type
    sample_attribute_type factory: :sample_sample_attribute_type
  end
  
  factory(:sample_multi_sample_attribute, parent: :sample_attribute) do
    sequence(:title) { |n| "sample attribute #{n}" }
    linked_sample_type factory: :simple_sample_type
    sample_attribute_type factory: :sample_multi_sample_attribute_type
  end
  
  factory(:apples_controlled_vocab_attribute, parent: :sample_attribute) do
    sequence(:title) { |n| "apples controlled vocab attribute #{n}" }
    after_build do |type|
      type.sample_controlled_vocab = Factory.build(:apples_sample_controlled_vocab)
      type.sample_attribute_type = Factory(:controlled_vocab_attribute_type)
    end
  end
  
  factory(:apples_list_controlled_vocab_attribute, parent: :sample_attribute) do
    sequence(:title) { |n| "apples list controlled vocab attribute #{n}" }
    after_build do |type|
      type.sample_controlled_vocab = Factory.build(:apples_sample_controlled_vocab)
      type.sample_attribute_type = Factory(:cv_list_attribute_type)
    end
  end
  
  factory(:string_sample_attribute_with_description_and_pid, parent: :sample_attribute) do
    sample_attribute_type factory: :string_sample_attribute_type
    description { "sample_attribute_description" }
    pid { "sample_attribute:pid" }
    required { true }
  end
end
