# SampleAttribute
Factory.define(:sample_attribute) do |f|
  f.sequence(:title) { |n| "Sample attribute #{n}" }
  f.association :sample_type, factory: :sample_type
end

# a string that must contain 'xxx'
Factory.define(:simple_string_sample_attribute, parent: :sample_attribute) do |f|
  f.sample_attribute_type factory: :xxx_string_sample_attribute_type
  f.required true
end

Factory.define(:any_string_sample_attribute, parent: :sample_attribute) do |f|
  f.sample_attribute_type factory: :string_sample_attribute_type
  f.required true
end

Factory.define(:data_file_sample_attribute, parent: :sample_attribute) do |f|
  f.sample_attribute_type factory: :data_file_sample_attribute_type
  f.required true
end

Factory.define(:sample_sample_attribute, parent: :sample_attribute) do |f|
  f.sequence(:title) { |n| "sample attribute #{n}" }
  f.linked_sample_type factory: :simple_sample_type
  f.sample_attribute_type factory: :sample_sample_attribute_type
end

Factory.define(:sample_multi_sample_attribute, parent: :sample_attribute) do |f|
  f.sequence(:title) { |n| "sample attribute #{n}" }
  f.linked_sample_type factory: :simple_sample_type
  f.sample_attribute_type factory: :sample_multi_sample_attribute_type
end

Factory.define(:apples_controlled_vocab_attribute, parent: :sample_attribute) do |f|
  f.sequence(:title) { |n| "apples controlled vocab attribute #{n}" }
  f.after_build do |type|
    type.sample_controlled_vocab = Factory.build(:apples_sample_controlled_vocab)
    type.sample_attribute_type = Factory(:controlled_vocab_attribute_type)
  end
end

Factory.define(:string_sample_attribute_with_description_and_iri, parent: :sample_attribute) do |f|
  f.sample_attribute_type factory: :string_sample_attribute_type
  f.description "sample_attribute_description"
  f.iri "iri for sample attribute"
  f.required true
end
