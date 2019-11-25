# SampleType
Factory.define(:sample_type) do |f|
  f.sequence(:title) { |n| "SampleType #{n}" }
  f.with_project_contributor
  #f.projects { [Factory.build(:project)] }
end

Factory.define(:patient_sample_type, parent: :sample_type) do |f|
  f.title 'Patient data'
  f.after_build do |type|
    # Not sure why i have to explicitly add the sample_type association
    type.sample_attributes << Factory.build(:sample_attribute, title: 'full name', sample_attribute_type: Factory(:full_name_sample_attribute_type), required: true, is_title: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'age', sample_attribute_type: Factory(:age_sample_attribute_type), required: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'weight', sample_attribute_type: Factory(:weight_sample_attribute_type), unit: Unit.find_or_create_by(symbol:'g',comment:'gram'), required: false, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'address', sample_attribute_type: Factory(:address_sample_attribute_type), required: false, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'postcode', sample_attribute_type: Factory(:postcode_sample_attribute_type), required: false, sample_type: type)
  end
end

Factory.define(:simple_sample_type, parent: :sample_type) do |f|
  f.sequence(:title) { |n| "Simple Sample Type #{n}" }
  f.after_build do |type|
    type.sample_attributes << Factory.build(:sample_attribute, title: 'the title', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
  end
end

Factory.define(:strain_sample_type, parent: :sample_type) do |f|
  f.title 'Strain type'
  f.association :content_blob, factory: :strain_sample_data_content_blob
  f.uploaded_template true
  f.after_build do |type|
    type.sample_attributes << Factory.build(:sample_attribute, template_column_index: 1, title: 'name', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, template_column_index: 2, title: 'seekstrain', sample_attribute_type: Factory(:strain_sample_attribute_type), required: true, sample_type: type)
  end
end

Factory.define(:optional_strain_sample_type, parent: :strain_sample_type) do |f|
  f.after_build do |type|
    type.sample_attributes = [Factory.build(:sample_attribute, template_column_index: 1, title: 'name', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, sample_type: type),
                              Factory.build(:sample_attribute, template_column_index: 2, title: 'seekstrain', sample_attribute_type: Factory(:strain_sample_attribute_type), required: false, sample_type: type)]
  end
end

Factory.define(:apples_controlled_vocab_sample_type, parent: :sample_type) do |f|
  f.sequence(:title) { |n| "apples controlled vocab sample type #{n}" }
  f.after_build do |type|
    type.sample_attributes << Factory.build(:apples_controlled_vocab_attribute, title: 'apples', is_title: true, required: true, sample_type: type)
  end
end

Factory.define(:linked_sample_type, parent: :sample_type) do |f|
  f.sequence(:title) { |n| "linked sample type #{n}" }
  f.after_build do |type|
    type.sample_attributes << Factory.build(:sample_attribute, title: 'title', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_sample_attribute, title: 'patient', linked_sample_type: Factory(:patient_sample_type,projects:type.projects,contributor:type.contributor), required: true, sample_type: type)
  end
end

Factory.define(:linked_sample_type_to_self, parent: :sample_type) do |f|
  f.sequence(:title) { |n| "linked sample type #{n}" }
  f.after_build do |type|
    type.sample_attributes << Factory.build(:sample_attribute, title: 'title', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_sample_attribute, title: 'self', linked_sample_type: type, required: true, sample_type: type)
  end
end

Factory.define(:source_sample_type, parent: :sample_type) do |f|
  f.title 'Library'
  f.after_build do |type|
    type.sample_attributes << Factory.build(:sample_attribute, title: 'title', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'info', sample_attribute_type: Factory(:string_sample_attribute_type), required: false, sample_type: type)
  end
end

Factory.define(:linked_optional_sample_type, parent: :sample_type) do |f|
  f.sequence(:title) { |n| "linked sample type #{n}" }
  f.after_build do |type|
    type.sample_attributes << Factory.build(:sample_attribute, title: 'title', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_sample_attribute, title: 'patient', linked_sample_type: Factory(:patient_sample_type,project_ids:type.projects.collect(&:id)), required: false, sample_type: type)
  end
end
