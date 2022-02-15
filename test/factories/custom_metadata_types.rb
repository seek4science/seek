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