Factory.define(:age_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'age'
  f.association :sample_attribute_type, factory: :integer_sample_attribute_type
end

Factory.define(:name_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'name'
  f.association :sample_attribute_type, factory: :string_sample_attribute_type
end

Factory.define(:datetime_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'date'
  f.association :sample_attribute_type, factory: :datetime_sample_attribute_type
end

Factory.define(:simple_investigation_custom_metadata_type,class: CustomMetadataType) do |f|
  f.title 'simple investigation custom metadata type'
  f.supported_type 'Investigation'
  f.after_build do |a|
    a.custom_metadata_attributes << Factory(:age_custom_metadata_attribute)
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, required: true)
    a.custom_metadata_attributes << Factory(:datetime_custom_metadata_attribute)
  end
end

Factory.define(:simple_study_custom_metadata_type, parent: :simple_investigation_custom_metadata_type) do |f|
  f.title 'simple study custom metadata type'
  f.supported_type 'Study'
end