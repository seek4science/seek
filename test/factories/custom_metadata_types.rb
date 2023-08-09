FactoryBot.define do
  factory(:age_custom_metadata_attribute,class:CustomMetadataAttribute) do
    title { 'age' }
    association :sample_attribute_type, factory: :integer_sample_attribute_type
  end

  factory(:age_custom_metadata_attribute_with_description_and_label,class:CustomMetadataAttribute) do
    title { 'age' }
    association :sample_attribute_type, factory: :integer_sample_attribute_type
    description { 'You need to enter age.' }
    label { 'Biological age' }
  end

  factory(:name_custom_metadata_attribute,class:CustomMetadataAttribute) do
    title { 'name' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:datetime_custom_metadata_attribute,class:CustomMetadataAttribute) do
    title { 'date' }
    association :sample_attribute_type, factory: :datetime_sample_attribute_type
  end

  factory(:study_custom_metadata_type_with_cv_and_cv_list_type, class: CustomMetadataType) do
    title { 'study custom metadata type with and list attributes' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'apple name')
      cv_list_attribute = CustomMetadataAttribute.new(title: 'apple list', sample_attribute_type: FactoryBot.create(:cv_list_attribute_type),
                                                      sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab), description: "apple samples list", label: "apple samples list")
      a.custom_metadata_attributes << cv_list_attribute
      cv_attribute = CustomMetadataAttribute.new(title: 'apple controlled vocab', sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type),
                                                 sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab), description: "apple samples controlled vocab", label: "apple samples controlled vocab")
      a.custom_metadata_attributes << cv_attribute
    end
  end

  factory(:cv_list_custom_metadata_attribute,class:CustomMetadataAttribute) do
    title { 'CVList' }
    association :sample_attribute_type, factory: :datetime_sample_attribute_type
  end

  factory(:simple_investigation_custom_metadata_type,class: CustomMetadataType) do
    title { 'simple investigation custom metadata type' }
    supported_type { 'Investigation' }
    after(:build) do |a|
      a.custom_metadata_attributes << FactoryBot.create(:age_custom_metadata_attribute)
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, required: true)
      a.custom_metadata_attributes << FactoryBot.create(:datetime_custom_metadata_attribute)
    end
  end

  factory(:simple_investigation_custom_metadata_type_with_description_and_label,class: CustomMetadataType) do
    title { 'simple investigation custom metadata type' }
    supported_type { 'Investigation' }
    after(:build) do |a|
      a.custom_metadata_attributes << FactoryBot.create(:age_custom_metadata_attribute_with_description_and_label)
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, required: true)
      a.custom_metadata_attributes << FactoryBot.create(:datetime_custom_metadata_attribute)
    end
  end

  factory(:simple_study_custom_metadata_type, parent: :simple_investigation_custom_metadata_type) do
    title { 'simple study custom metadata type' }
    supported_type { 'Study' }
  end

  factory(:simple_assay_custom_metadata_type, parent: :simple_investigation_custom_metadata_type) do
    title { 'simple study custom metadata type' }
    supported_type { 'Assay' }
  end

  factory(:study_custom_metadata_type_with_spaces, class: CustomMetadataType) do
    title { 'study custom metadata type with spaces' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'full name')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'full address')
    end
  end


  factory(:study_custom_metadata_type_with_clashes, class: CustomMetadataType) do
    title { 'study custom metadata type with clashes' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'Full name')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'full name')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'full  name')
    end
  end

  factory(:study_custom_metadata_type_with_symbols, class: CustomMetadataType) do
    title { 'study custom metadata type with symbols' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'+name')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'-name')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'&name')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'name(name)')
    end
  end

  factory(:study_custom_metadata_type_for_MIAPPE, class: CustomMetadataType) do
    title { 'MIAPPE metadata' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'id')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'study_start_date')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'study_end_date')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'contact_institution')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'geographic_location_country')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'experimental_site_name')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'latitude')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'longitude')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'altitude')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'description_of_the_experimental_design')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'type_of_experimental_design')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'observation_unit_level_hierarchy')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'observation_unit_description')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'description_of_growth_facility')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'type_of_growth_facility')
      a.custom_metadata_attributes << FactoryBot.create(:name_custom_metadata_attribute, title:'cultural_practices')
    end
  end

  # for testing linked custom metadata
  factory(:first_name_custom_metadata_attribute,class:CustomMetadataAttribute) do
    title { 'first_name' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:last_name_custom_metadata_attribute,class:CustomMetadataAttribute) do
    title { 'last_name' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:street_custom_metadata_attribute,class:CustomMetadataAttribute) do
    title { 'street' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:city_custom_metadata_attribute,class:CustomMetadataAttribute) do
    title { 'city' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:role_email_custom_metadata_attribute,class:CustomMetadataAttribute) do
    title { 'role_email' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:role_phone_custom_metadata_attribute,class:CustomMetadataAttribute) do
    title { 'role_phone' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:role_name_custom_metadata_type,class:CustomMetadataType) do
    title { 'role_name' }
    supported_type { 'CustomMetadata' }
    after(:build) do |a|
      a.custom_metadata_attributes << FactoryBot.create(:first_name_custom_metadata_attribute,required: true)
      a.custom_metadata_attributes << FactoryBot.create(:last_name_custom_metadata_attribute, required: true)
    end
  end

  factory(:role_address_custom_metadata_type,class:CustomMetadataType) do
    title { 'role_address' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.custom_metadata_attributes << FactoryBot.create(:street_custom_metadata_attribute,required: true)
      a.custom_metadata_attributes << FactoryBot.create(:city_custom_metadata_attribute, required: true)
    end
  end

  factory(:role_name_linked_custom_metadata_attribute,class:CustomMetadataAttribute) do
    title { 'role_name' }
    association :sample_attribute_type, factory: :custom_metadata_sample_attribute_type
    association :linked_custom_metadata_type, factory: :role_name_custom_metadata_type
  end

  factory(:role_address_linked_custom_metadata_attribute,class:CustomMetadataAttribute) do
    title { 'role_address' }
    association :sample_attribute_type, factory: :custom_metadata_sample_attribute_type
    association :linked_custom_metadata_type, factory: :role_address_custom_metadata_type
  end

  factory(:role_custom_metadata_type,class:CustomMetadataType) do
    title { 'role' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.custom_metadata_attributes << FactoryBot.create(:role_email_custom_metadata_attribute,required: true)
      a.custom_metadata_attributes << FactoryBot.create(:role_phone_custom_metadata_attribute,required: true)
      a.custom_metadata_attributes << FactoryBot.create(:role_name_linked_custom_metadata_attribute)
    end
  end

  factory(:role_multiple_custom_metadata_type,class:CustomMetadataType) do
    title { 'role' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.custom_metadata_attributes << FactoryBot.create(:role_email_custom_metadata_attribute,required: true)
      a.custom_metadata_attributes << FactoryBot.create(:role_phone_custom_metadata_attribute,required: true)
      a.custom_metadata_attributes << FactoryBot.create(:role_name_linked_custom_metadata_attribute)
      a.custom_metadata_attributes << FactoryBot.create(:role_address_linked_custom_metadata_attribute)
    end
  end

  factory(:dad_linked_custom_metadata_attribute,class:CustomMetadataAttribute) do
    title { 'dad' }
    association :sample_attribute_type, factory: :custom_metadata_sample_attribute_type
    association :linked_custom_metadata_type, factory: :role_name_custom_metadata_type
  end

  factory(:mom_linked_custom_metadata_attribute,class:CustomMetadataAttribute) do
    title { 'mom' }
    association :sample_attribute_type, factory: :custom_metadata_sample_attribute_type
    association :linked_custom_metadata_type, factory: :role_name_custom_metadata_type
  end

  factory(:child_name_linked_custom_metadata_attribute_multi_attribute,class:CustomMetadataAttribute) do
    title { 'child' }
    association :sample_attribute_type, factory: :custom_metadata_multi_sample_attribute_type
    association :linked_custom_metadata_type, factory: :role_name_custom_metadata_type
  end

  factory(:family_custom_metadata_type,class:CustomMetadataType) do
    title { 'family' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.custom_metadata_attributes << FactoryBot.create(:dad_linked_custom_metadata_attribute,required: true)
      a.custom_metadata_attributes << FactoryBot.create(:mom_linked_custom_metadata_attribute,required: true)
      a.custom_metadata_attributes << FactoryBot.create(:child_name_linked_custom_metadata_attribute_multi_attribute)
    end
  end


  # for testing linked custom metadata multi
  factory(:role_affiliation_name_custom_metadata_attribute,class:CustomMetadataAttribute) do
    title { 'role_affiliation_name' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end


  factory(:identifier_custom_metadata_attribute,class:CustomMetadataAttribute) do
    title { 'identifier' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:scheme_custom_metadata_attribute,class:CustomMetadataAttribute) do
    title { 'scheme' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end



  factory(:role_affiliation_identifiers_linked_custom_metadata_attribute_multi_attribute,class:CustomMetadataAttribute) do
    title { 'role_affiliation_identifiers' }
    association :sample_attribute_type, factory: :custom_metadata_multi_sample_attribute_type
    association :linked_custom_metadata_type, factory: :role_affiliation_identifiers_custom_metadata_type
  end

  factory(:role_affiliation_identifiers_custom_metadata_type,class:CustomMetadataType) do
    title { 'role_affiliation_identifiers' }
    supported_type { 'CustomMetadata' }
    after(:build) do |a|
      a.custom_metadata_attributes << FactoryBot.create(:identifier_custom_metadata_attribute, required: true)
      a.custom_metadata_attributes << FactoryBot.create(:scheme_custom_metadata_attribute, required: true)
    end
  end


  factory(:role_affiliation_custom_metadata_type,class:CustomMetadataType) do
    title { 'role_affiliation' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.custom_metadata_attributes << FactoryBot.create(:role_affiliation_name_custom_metadata_attribute,required: true)
      a.custom_metadata_attributes << FactoryBot.create(:role_affiliation_identifiers_linked_custom_metadata_attribute_multi_attribute,required:true)
    end
  end


end

