FactoryBot.define do
  factory(:age_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'age' }
    association :sample_attribute_type, factory: :integer_sample_attribute_type
  end

  factory(:age_extended_metadata_attribute_with_description_and_label,class:ExtendedMetadataAttribute) do
    title { 'age' }
    association :sample_attribute_type, factory: :integer_sample_attribute_type
    description { 'You need to enter age.' }
    label { 'Biological age' }
  end

  factory(:name_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'name' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:datetime_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'date' }
    association :sample_attribute_type, factory: :datetime_sample_attribute_type
  end

  factory(:min_extended_metadata_type,class: ExtendedMetadataType) do
    title { 'A Min Extended Metadata Type' }
    supported_type { 'Investigation' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, required: true)
    end
  end

  factory(:max_extended_metadata_type,class: ExtendedMetadataType) do
    title { 'A Max Extended Metadata Type' }
    supported_type { 'Investigation' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:age_extended_metadata_attribute)
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, required: true)
      a.extended_metadata_attributes << FactoryBot.create(:datetime_extended_metadata_attribute)
    end
  end

  factory(:study_extended_metadata_type_with_cv_and_cv_list_type, class: ExtendedMetadataType) do
    title { 'study extended metadata type with and list attributes' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'apple name')
      cv_list_attribute = ExtendedMetadataAttribute.new(title: 'apple list', sample_attribute_type: FactoryBot.create(:cv_list_attribute_type),
                                                      sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab), description: "apple samples list", label: "apple samples list")
      a.extended_metadata_attributes << cv_list_attribute
      cv_attribute = ExtendedMetadataAttribute.new(title: 'apple controlled vocab', sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type),
                                                 sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab), description: "apple samples controlled vocab", label: "apple samples controlled vocab")
      a.extended_metadata_attributes << cv_attribute
    end
  end

  factory(:cv_list_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'CVList' }
    association :sample_attribute_type, factory: :datetime_sample_attribute_type
  end

  factory(:simple_investigation_extended_metadata_type,class: ExtendedMetadataType) do
    title { 'simple investigation extended metadata type' }
    supported_type { 'Investigation' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:age_extended_metadata_attribute)
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, required: true)
      a.extended_metadata_attributes << FactoryBot.create(:datetime_extended_metadata_attribute)
    end
  end

  factory(:simple_investigation_extended_metadata_type_with_description_and_label,class: ExtendedMetadataType) do
    title { 'simple investigation extended metadata type' }
    supported_type { 'Investigation' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:age_extended_metadata_attribute_with_description_and_label)
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, required: true)
      a.extended_metadata_attributes << FactoryBot.create(:datetime_extended_metadata_attribute)
    end
  end

  factory(:simple_study_extended_metadata_type, parent: :simple_investigation_extended_metadata_type) do
    title { 'simple study extended metadata type' }
    supported_type { 'Study' }
  end

  factory(:simple_assay_extended_metadata_type, parent: :simple_investigation_extended_metadata_type) do
    title { 'simple study extended metadata type' }
    supported_type { 'Assay' }
  end

  factory(:simple_document_extended_metadata_type, parent: :simple_investigation_extended_metadata_type) do
    title { 'simple document extended metadata type' }
    supported_type { 'Document' }
  end

  factory(:simple_model_extended_metadata_type, parent: :simple_investigation_extended_metadata_type) do
    title { 'simple model extended metadata type' }
    supported_type { 'Model' }
    end

  factory(:simple_data_file_extended_metadata_type, parent: :simple_investigation_extended_metadata_type) do
    title { 'simple data file extended metadata type' }
    supported_type { 'DataFile' }
  end

  factory(:simple_collection_extended_metadata_type, parent: :simple_investigation_extended_metadata_type) do
    title { 'simple collection extended metadata type' }
    supported_type { 'Collection' }
  end

  factory(:simple_sop_extended_metadata_type, parent: :simple_investigation_extended_metadata_type) do
    title { 'simple sop extended metadata type' }
    supported_type { 'Sop' }
  end

  factory(:simple_presentation_extended_metadata_type, parent: :simple_investigation_extended_metadata_type) do
    title { 'simple presentation extended metadata type' }
    supported_type { 'Presentation' }
  end

  factory(:simple_project_extended_metadata_type, parent: :simple_investigation_extended_metadata_type) do
    title { 'simple project extended metadata type' }
    supported_type { 'Project' }
  end

  factory(:simple_event_extended_metadata_type, parent: :simple_investigation_extended_metadata_type) do
    title { 'simple event extended metadata type' }
    supported_type { 'Event' }
  end

  factory(:study_extended_metadata_type_with_spaces, class: ExtendedMetadataType) do
    title { 'study extended metadata type with spaces' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'full name')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'full address')
    end
  end


  factory(:study_extended_metadata_type_with_clashes, class: ExtendedMetadataType) do
    title { 'study extended metadata type with clashes' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'Full name')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'full name')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'full  name')
    end
  end

  factory(:study_extended_metadata_type_with_symbols, class: ExtendedMetadataType) do
    title { 'study extended metadata type with symbols' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'+name')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'-name')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'&name')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'name(name)')
    end
  end

  factory(:study_extended_metadata_type_for_MIAPPE, class: ExtendedMetadataType) do
    title { ExtendedMetadataType::MIAPPE_TITLE }
    supported_type { 'Study' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'id')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'study_start_date')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'study_end_date')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'contact_institution')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'geographic_location_country')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'experimental_site_name')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'latitude')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'longitude')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'altitude')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'description_of_the_experimental_design')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'type_of_experimental_design')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'observation_unit_level_hierarchy')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'observation_unit_description')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'description_of_growth_facility')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'type_of_growth_facility')
      a.extended_metadata_attributes << FactoryBot.create(:name_extended_metadata_attribute, title:'cultural_practices')
    end
  end

  # for testing linked extended metadata
  factory(:first_name_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'first_name' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:last_name_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'last_name' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:street_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'street' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:city_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'city' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:role_email_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'role_email' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:role_phone_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'role_phone' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:role_name_extended_metadata_type,class:ExtendedMetadataType) do
    title { 'role_name' }
    supported_type { 'ExtendedMetadata' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:first_name_extended_metadata_attribute,required: true)
      a.extended_metadata_attributes << FactoryBot.create(:last_name_extended_metadata_attribute, required: true)
    end
  end

  factory(:role_address_extended_metadata_type,class:ExtendedMetadataType) do
    title { 'role_address' }
    supported_type { 'ExtendedMetadata' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:street_extended_metadata_attribute,required: true)
      a.extended_metadata_attributes << FactoryBot.create(:city_extended_metadata_attribute, required: true)
    end
  end

  factory(:role_name_linked_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'role_name' }
    association :sample_attribute_type, factory: :extended_metadata_sample_attribute_type
    association :linked_extended_metadata_type, factory: :role_name_extended_metadata_type
  end

  factory(:role_address_linked_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'role_address' }
    association :sample_attribute_type, factory: :extended_metadata_sample_attribute_type
    association :linked_extended_metadata_type, factory: :role_address_extended_metadata_type
  end

  factory(:role_extended_metadata_type,class:ExtendedMetadataType) do
    title { 'role' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:role_email_extended_metadata_attribute,required: true)
      a.extended_metadata_attributes << FactoryBot.create(:role_phone_extended_metadata_attribute,required: true)
      a.extended_metadata_attributes << FactoryBot.create(:role_name_linked_extended_metadata_attribute)
    end
  end

  factory(:role_multiple_extended_metadata_type,class:ExtendedMetadataType) do
    title { 'role' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:role_email_extended_metadata_attribute,required: true)
      a.extended_metadata_attributes << FactoryBot.create(:role_phone_extended_metadata_attribute,required: true)
      a.extended_metadata_attributes << FactoryBot.create(:role_name_linked_extended_metadata_attribute)
      a.extended_metadata_attributes << FactoryBot.create(:role_address_linked_extended_metadata_attribute)
    end
  end

  factory(:dad_linked_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'dad' }
    association :sample_attribute_type, factory: :extended_metadata_sample_attribute_type
    association :linked_extended_metadata_type, factory: :role_name_extended_metadata_type
  end

  factory(:mom_linked_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'mom' }
    association :sample_attribute_type, factory: :extended_metadata_sample_attribute_type
    association :linked_extended_metadata_type, factory: :role_name_extended_metadata_type
  end

  factory(:child_name_linked_extended_metadata_attribute_multi_attribute,class:ExtendedMetadataAttribute) do
    title { 'child' }
    association :sample_attribute_type, factory: :extended_metadata_multi_sample_attribute_type
    association :linked_extended_metadata_type, factory: :role_name_extended_metadata_type
  end

  factory(:family_extended_metadata_type,class:ExtendedMetadataType) do
    title { 'family' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:dad_linked_extended_metadata_attribute,required: true)
      a.extended_metadata_attributes << FactoryBot.create(:mom_linked_extended_metadata_attribute,required: true)
      a.extended_metadata_attributes << FactoryBot.create(:child_name_linked_extended_metadata_attribute_multi_attribute)
    end
  end


  # for testing linked extended metadata multi

  # case 1
  factory(:role_affiliation_name_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'role_affiliation_name' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end


  factory(:identifier_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'identifier' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:scheme_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'scheme' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end



  factory(:role_affiliation_identifiers_linked_extended_metadata_attribute_multi_attribute,class:ExtendedMetadataAttribute) do
    title { 'role_affiliation_identifiers' }
    association :sample_attribute_type, factory: :extended_metadata_multi_sample_attribute_type
    association :linked_extended_metadata_type, factory: :role_affiliation_identifiers_extended_metadata_type
  end

  factory(:role_affiliation_identifiers_extended_metadata_type,class:ExtendedMetadataType) do
    title { 'role_affiliation_identifiers' }
    supported_type { 'ExtendedMetadata' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:identifier_extended_metadata_attribute, required: true)
      a.extended_metadata_attributes << FactoryBot.create(:scheme_extended_metadata_attribute, required: true)
    end
  end


  factory(:role_affiliation_extended_metadata_type,class:ExtendedMetadataType) do
    title { 'role_affiliation' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:role_affiliation_name_extended_metadata_attribute,required: true)
      a.extended_metadata_attributes << FactoryBot.create(:role_affiliation_identifiers_linked_extended_metadata_attribute_multi_attribute,required:true)
    end
  end


  # case 2


  factory(:study_title_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'study_title' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:study_site_name_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'study_site_name' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:study_site_location_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'study_site_location' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:participant_name_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'participant_name' }
    association :sample_attribute_type, factory: :extended_metadata_sample_attribute_type
    association :linked_extended_metadata_type, factory: :role_name_extended_metadata_type
  end


  factory(:participant_age_extended_metadata_attribute,class:ExtendedMetadataAttribute) do
    title { 'participant_age' }
    association :sample_attribute_type, factory: :string_sample_attribute_type
  end

  factory(:participants_extended_metadata_type,class:ExtendedMetadataType) do
    title { 'participants' }
    supported_type { 'ExtendedMetadata' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:participant_name_extended_metadata_attribute, required: true)
      a.extended_metadata_attributes << FactoryBot.create(:participant_age_extended_metadata_attribute)
    end
  end


  factory(:participants_linked_extended_metadata_attribute_multi_attribute,class:ExtendedMetadataAttribute) do
    title { 'participants' }
    association :sample_attribute_type, factory: :extended_metadata_multi_sample_attribute_type
    association :linked_extended_metadata_type, factory: :participants_extended_metadata_type
  end


  factory(:study_sites_extended_metadata_type,class:ExtendedMetadataType) do
    title { 'study_sites' }
    supported_type { 'ExtendedMetadata' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:study_site_name_extended_metadata_attribute, required: true)
      a.extended_metadata_attributes << FactoryBot.create(:study_site_location_extended_metadata_attribute)
      a.extended_metadata_attributes << FactoryBot.create(:participants_linked_extended_metadata_attribute_multi_attribute,required:true)
    end
  end

  factory(:study_sites_linked_extended_metadata_attribute_multi_attribute,class:ExtendedMetadataAttribute) do
    title { 'study_sites' }
    association :sample_attribute_type, factory: :extended_metadata_multi_sample_attribute_type
    association :linked_extended_metadata_type, factory: :study_sites_extended_metadata_type
  end

  factory(:study_extended_metadata_type,class:ExtendedMetadataType) do
    title { 'study_model' }
    supported_type { 'Study' }
    after(:build) do |a|
      a.extended_metadata_attributes << FactoryBot.create(:study_title_extended_metadata_attribute,required: true)
      a.extended_metadata_attributes << FactoryBot.create(:study_sites_linked_extended_metadata_attribute_multi_attribute)
    end
  end

end

