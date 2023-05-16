Factory.define(:age_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'age'
  f.association :sample_attribute_type, factory: :integer_sample_attribute_type
end

Factory.define(:age_custom_metadata_attribute_with_description_and_label,class:CustomMetadataAttribute) do |f|
  f.title 'age'
  f.association :sample_attribute_type, factory: :integer_sample_attribute_type
  f.description 'You need to enter age.'
  f.label 'Biological age'
end

Factory.define(:name_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'name'
  f.association :sample_attribute_type, factory: :string_sample_attribute_type
end

Factory.define(:datetime_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'date'
  f.association :sample_attribute_type, factory: :datetime_sample_attribute_type
end

Factory.define(:cv_list_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'CVList'
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

Factory.define(:simple_investigation_custom_metadata_type_with_description_and_label,class: CustomMetadataType) do |f|
  f.title 'simple investigation custom metadata type'
  f.supported_type 'Investigation'
  f.after_build do |a|
    a.custom_metadata_attributes << Factory(:age_custom_metadata_attribute_with_description_and_label)
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, required: true)
    a.custom_metadata_attributes << Factory(:datetime_custom_metadata_attribute)
  end
end

Factory.define(:simple_study_custom_metadata_type, parent: :simple_investigation_custom_metadata_type) do |f|
  f.title 'simple study custom metadata type'
  f.supported_type 'Study'
end

Factory.define(:simple_assay_custom_metadata_type, parent: :simple_investigation_custom_metadata_type) do |f|
  f.title 'simple study custom metadata type'
  f.supported_type 'Assay'
end

Factory.define(:study_custom_metadata_type_with_spaces, class: CustomMetadataType) do |f|
  f.title 'study custom metadata type with spaces'
  f.supported_type 'Study'
  f.after_build do |a|
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'full name')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'full address')
  end
end


Factory.define(:study_custom_metadata_type_with_cv_and_cv_list_type, class: CustomMetadataType) do |f|
  f.title 'study custom metadata type with and list attributes'
  f.supported_type 'Study'
  f.after_build do |a|
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'apple name')
    cv_list_attribute = CustomMetadataAttribute.new(title: 'apple list', sample_attribute_type: Factory(:cv_list_attribute_type),
                                                    sample_controlled_vocab: Factory(:apples_sample_controlled_vocab), description: "apple samples list", label: "apple samples list")
    a.custom_metadata_attributes << cv_list_attribute
    cv_attribute = CustomMetadataAttribute.new(title: 'apple controlled vocab', sample_attribute_type: Factory(:controlled_vocab_attribute_type),
                                               sample_controlled_vocab: Factory(:apples_sample_controlled_vocab), description: "apple samples controlled vocab", label: "apple samples controlled vocab")
    a.custom_metadata_attributes << cv_attribute
  end
end

Factory.define(:study_custom_metadata_type_with_clashes, class: CustomMetadataType) do |f|
  f.title 'study custom metadata type with clashes'
  f.supported_type 'Study'
  f.after_build do |a|
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'Full name')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'full name')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'full  name')
  end
end

Factory.define(:study_custom_metadata_type_with_symbols, class: CustomMetadataType) do |f|
  f.title 'study custom metadata type with symbols'
  f.supported_type 'Study'
  f.after_build do |a|
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'+name')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'-name')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'&name')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'name(name)')
  end
end

Factory.define(:study_custom_metadata_type_for_MIAPPE, class: CustomMetadataType) do |f|
  f.title 'MIAPPE metadata'
  f.supported_type 'Study'
  f.after_build do |a|
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'id')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'study_start_date')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'study_end_date')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'contact_institution')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'geographic_location_country')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'experimental_site_name')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'latitude')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'longitude')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'altitude')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'description_of_the_experimental_design')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'type_of_experimental_design')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'observation_unit_level_hierarchy')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'observation_unit_description')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'description_of_growth_facility')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'type_of_growth_facility')
    a.custom_metadata_attributes << Factory(:name_custom_metadata_attribute, title:'cultural_practices')
  end
end

# for testing linked custom metadata
Factory.define(:first_name_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'first_name'
  f.association :sample_attribute_type, factory: :string_sample_attribute_type
end

Factory.define(:last_name_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'last_name'
  f.association :sample_attribute_type, factory: :string_sample_attribute_type
end

Factory.define(:street_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'street'
  f.association :sample_attribute_type, factory: :string_sample_attribute_type
end

Factory.define(:city_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'city'
  f.association :sample_attribute_type, factory: :string_sample_attribute_type
end

Factory.define(:role_email_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'role_email'
  f.association :sample_attribute_type, factory: :string_sample_attribute_type
end

Factory.define(:role_phone_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'role_phone'
  f.association :sample_attribute_type, factory: :string_sample_attribute_type
end


Factory.define(:role_name_custom_metadata_type,class:CustomMetadataType) do |f|
  f.title 'role_name'
  f.supported_type 'Study'
  f.after_build do |a|
    a.custom_metadata_attributes << Factory(:first_name_custom_metadata_attribute,required: true)
    a.custom_metadata_attributes << Factory(:last_name_custom_metadata_attribute, required: true)
  end
end

Factory.define(:role_address_custom_metadata_type,class:CustomMetadataType) do |f|
  f.title 'role_address'
  f.supported_type 'Study'
  f.after_build do |a|
    a.custom_metadata_attributes << Factory(:street_custom_metadata_attribute,required: true)
    a.custom_metadata_attributes << Factory(:city_custom_metadata_attribute, required: true)
  end
end

Factory.define(:role_name_linked_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'role_name'
  f.association :sample_attribute_type, factory: :custom_metadata_sample_attribute_type
  f.association :linked_custom_metadata_type, factory: :role_name_custom_metadata_type
end

Factory.define(:role_address_linked_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'role_address'
  f.association :sample_attribute_type, factory: :custom_metadata_sample_attribute_type
  f.association :linked_custom_metadata_type, factory: :role_address_custom_metadata_type
end

Factory.define(:role_custom_metadata_type,class:CustomMetadataType) do |f|
  f.title 'role'
  f.supported_type 'Study'
  f.after_build do |a|
    a.custom_metadata_attributes << Factory(:role_email_custom_metadata_attribute,required: true)
    a.custom_metadata_attributes << Factory(:role_phone_custom_metadata_attribute,required: true)
    a.custom_metadata_attributes << Factory(:role_name_linked_custom_metadata_attribute)
  end
end

Factory.define(:role_multiple_custom_metadata_type,class:CustomMetadataType) do |f|
  f.title 'role'
  f.supported_type 'Study'
  f.after_build do |a|
    a.custom_metadata_attributes << Factory(:role_email_custom_metadata_attribute,required: true)
    a.custom_metadata_attributes << Factory(:role_phone_custom_metadata_attribute,required: true)
    a.custom_metadata_attributes << Factory(:role_name_linked_custom_metadata_attribute)
    a.custom_metadata_attributes << Factory(:role_address_linked_custom_metadata_attribute)
  end
end

Factory.define(:dad_linked_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'dad'
  f.association :sample_attribute_type, factory: :custom_metadata_sample_attribute_type
  f.association :linked_custom_metadata_type, factory: :role_name_custom_metadata_type
end

Factory.define(:mom_linked_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'mom'
  f.association :sample_attribute_type, factory: :custom_metadata_sample_attribute_type
  f.association :linked_custom_metadata_type, factory: :role_name_custom_metadata_type
end

Factory.define(:child_name_linked_custom_metadata_attribute,class:CustomMetadataAttribute) do |f|
  f.title 'child'
  f.association :sample_attribute_type, factory: :custom_metadata_sample_attribute_type
  f.association :linked_custom_metadata_type, factory: :role_name_custom_metadata_type
end

Factory.define(:family_custom_metadata_type,class:CustomMetadataType) do |f|
  f.title 'family'
  f.supported_type 'Study'
  f.after_build do |a|
    a.custom_metadata_attributes << Factory(:dad_linked_custom_metadata_attribute,required: true)
    a.custom_metadata_attributes << Factory(:mom_linked_custom_metadata_attribute,required: true)
    a.custom_metadata_attributes << Factory(:child_name_linked_custom_metadata_attribute)
  end
end