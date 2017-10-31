# SampleAttribute
Factory.define(:sample_attribute) do |f|
  f.sequence(:title) { |n| "Sample attribute #{n}" }
  f.association :sample_type, factory: :sample_type
end

# a string that must contain 'xxx'
Factory.define(:simple_string_sample_attribute, parent: :sample_attribute) do |f|
  f.required true
  f.after_build do |type|
    type.sample_attribute_type = Factory(:xxx_string_sample_attribute_type)
  end
end

Factory.define(:any_string_sample_attribute, parent: :sample_attribute) do |f|
  f.required true
  f.after_build do |type|
    type.sample_attribute_type = Factory(:string_sample_attribute_type)
  end
end

Factory.define(:sample_sample_attribute, parent: :sample_attribute) do |f|
  f.sequence(:title) { |n| "sample attribute #{n}" }
  f.after_build do |type|
    type.linked_sample_type = Factory(:simple_sample_type)
    type.sample_attribute_type = Factory(:sample_sample_attribute_type)
  end
end

Factory.define(:apples_controlled_vocab_attribute, parent: :sample_attribute) do |f|
  f.sequence(:title) { |n| "apples controlled vocab attribute #{n}" }
  f.after_build do |type|
    type.sample_controlled_vocab = Factory.build(:apples_sample_controlled_vocab)
    type.sample_attribute_type = Factory(:controlled_vocab_attribute_type)
  end
end
