puts 'Seeded My Study Metadata Example'

string_type = SampleAttributeType.find_or_initialize_by(title: 'String')
string_type.update(base_type: Seek::Samples::BaseType::STRING)

text_type = SampleAttributeType.find_or_initialize_by(title: 'Text')
text_type.update(base_type: Seek::Samples::BaseType::TEXT)

date_type = SampleAttributeType.find_or_initialize_by(title: 'Date')
date_type.update(base_type: Seek::Samples::BaseType::DATE)


date_time_type = SampleAttributeType.find_or_initialize_by(title: 'Date time')
date_time_type.update(base_type: Seek::Samples::BaseType::DATE_TIME)

int_type = SampleAttributeType.find_or_initialize_by(title: 'Integer')
int_type.update(base_type: Seek::Samples::BaseType::INTEGER, placeholder: '1')

float_type = SampleAttributeType.find_or_initialize_by(title: 'Real number')
float_type.update(base_type: Seek::Samples::BaseType::FLOAT, placeholder: '0.5')

boolean_type = SampleAttributeType.find_or_initialize_by(title: 'Boolean')
boolean_type.update(base_type: Seek::Samples::BaseType::BOOLEAN)

cv_type = SampleAttributeType.find_or_initialize_by(title: 'Controlled Vocabulary')
cv_type.update(base_type: Seek::Samples::BaseType::CV)

cv_type_list = SampleAttributeType.find_or_initialize_by(title: 'Controlled Vocabulary List')
cv_type_list.update(base_type: Seek::Samples::BaseType::CV_LIST)

linked_extended_metadata_type = SampleAttributeType.find_or_initialize_by(title: 'Linked Extended Metadata')
linked_extended_metadata_type.update(base_type: Seek::Samples::BaseType::LINKED_EXTENDED_METADATA)

linked_extended_metadata_type_list = SampleAttributeType.find_or_initialize_by(title: 'Linked Extended Metadata (multiple)')
linked_extended_metadata_type_list.update(base_type: Seek::Samples::BaseType::LINKED_EXTENDED_METADATA_MULTI)


def create_sample_controlled_vocab_terms_attributes(array)
  attributes = []
  array.each do |type|
    attributes << { label: type }
  end
  attributes
end


disable_authorization_checks do
  

  resource_use_rights_label_cv = SampleControlledVocab.where(title: 'Study Use Rights Label').first_or_create!(
    sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes(['CC0 1.0 (Creative Commons Zero v1.0 Universal)',
                                                                                               'CC BY 4.0 (Creative Commons Attribution 4.0 International)',
                                                                                               'CC BY-NC 4.0 (Creative Commons Attribution Non Commercial 4.0 International)',
                                                                                               'CC BY-SA 4.0 (Creative Commons Attribution Share Alike 4.0 International)',
                                                                                               'CC BY-NC-SA 4.0 (Creative Commons Attribution Non Commercial Share Alike 4.0 International)',
                                                                                               'All rights reserved',
                                                                                               'Other',
                                                                                               'Not applicable']))

  resource_use_rights_label = ExtendedMetadataAttribute.new(title: 'resource_use_rights_label', required: true, sample_attribute_type: cv_type, sample_controlled_vocab: resource_use_rights_label_cv)

  resource_use_rights_description = ExtendedMetadataAttribute.new(title: 'resource_use_rights_description', required: false, sample_attribute_type: text_type)

  resource_use_rights_authors_confirmation = ExtendedMetadataAttribute.new(title: 'resource_use_rights_authors_confirmation', required: true, sample_attribute_type: boolean_type)




  # Define role
  role_type_cv = SampleControlledVocab.where(title: 'Role Type').first_or_create!(
    sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes(['Contact', 'Principal investigator', 'Creator/Author', 'Funder (public)', 'Funder (private)',
                                                                                               'Sponsor (primary)', 'Sponsor (secondary)', 'Sponsor-Investigator', 'Data collector', 'Data curator',
                                                                                               'Data manager', 'Distributor', 'Editor', 'Hosting institution', 'Producer', 'Project leader', 'Project manager',
                                                                                               'Project member', 'Publisher', 'Registration agency', 'Registration authority', 'Related person', 'Researcher',
                                                                                               'Research group', 'Rights holder', 'Supervisor', 'Work package leader', 'Other']))


  role_name_personal_title_cv = SampleControlledVocab.where(title: 'Role Name Personal Title').first_or_create!(
    sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes(['Mr.', 'Ms.', 'Dr.', 'Prof. Dr.', 'Other']))

  role_name_identifier_scheme_cv = SampleControlledVocab.where(title: 'Role Name Identifier Scheme').first_or_create!(
    sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes(%w[ORCID ROR GRID ISNI]))



  unless ExtendedMetadataType.where(title:'role_name_identifiers', supported_type:'ExtendedMetadata').any?
    emt = ExtendedMetadataType.new(title: 'role_name_identifiers', supported_type:'ExtendedMetadata')

    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'scheme', required:true,
                                                                      sample_attribute_type: cv_type, sample_controlled_vocab: role_name_identifier_scheme_cv,
                                                                      description: "scheme")
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'identifier', sample_attribute_type: string_type )
    emt.save!
  end

  unless ExtendedMetadataType.where(title:'role_emt', supported_type:'ExtendedMetadata').any?
    emt = ExtendedMetadataType.new(title: 'role_emt', supported_type:'ExtendedMetadata')
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'role_name_personal_title', required:true,
                                                                      sample_attribute_type: cv_type, sample_controlled_vocab: role_name_personal_title_cv,
                                                                      description: "role_name_personal_title", label: "personal title")
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'first_name', sample_attribute_type: string_type, label: "first name", description: "First name of the role")
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'last_name', sample_attribute_type: string_type, label: "last name", description: "Last name of the role")
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'role_type', required:true,
                                                                      sample_attribute_type: cv_type, sample_controlled_vocab: role_type_cv, description: "role type", label: "Role type")


    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'role_name_identifiers',
                                                                      sample_attribute_type: linked_extended_metadata_type_list, linked_extended_metadata_type: ExtendedMetadataType.where(title:'role_name_identifiers', supported_type:'ExtendedMetadata').first )


    emt.save!
  end


  study_country_cv = SampleControlledVocab.where(title: 'European Study Country').first_or_create!(
    sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes(["Albania","Austria","Belgium","Bosnia and Herzegovina","Bulgaria","Croatia","Cyprus",
                                                                                               "Czech Republic","Denmark","Estonia","Finland","France","Germany","Greece","Hungary","Iceland","Ireland","Italy","Latvia","Lithuania","Luxembourg","Malta","Montenegro","Netherlands",
                                                                                               "North Macedonia","Norway","Poland","Portugal","Romania","Serbia","Slovakia","Slovenia","Spain","Sweden","Switzerland","United Kingdom",]))



  resource_type_general_cv = SampleControlledVocab.where(title: 'resource_type_general').first_or_create!(
    sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes(['Audiovisual', 'Book', 'Book chapter', 'Collection', 'Computational notebook',
                                                                                               'Conference paper', 'Conference proceeding', 'Data paper', 'Dataset',
                                                                                               'Dissertation', 'Event', 'Image', 'Interactive resource', 'Journal', 'Journal article',
                                                                                               'Model', 'Output management plan', 'Peer review', 'Physical object', 'Preprint',
                                                                                               'Report', 'Service', 'Software', 'Sound', 'Standard', 'Text', 'Workflow', 'Other'])
  )

  study_primary_design_cv = SampleControlledVocab.where(title: 'study_primary_design').first_or_create!(
    sample_controlled_vocab_terms_attributes: create_sample_controlled_vocab_terms_attributes(['Interventional','Non-Interventional'])
  )



  unless ExtendedMetadataType.where(title:'resource_use_rights_emt', supported_type:'ExtendedMetadata').any?
    emt = ExtendedMetadataType.new(title: 'resource_use_rights_emt', supported_type:'ExtendedMetadata')
    emt.extended_metadata_attributes << resource_use_rights_label
    emt.extended_metadata_attributes << resource_use_rights_description
    emt.extended_metadata_attributes << resource_use_rights_authors_confirmation

    emt.save!
  end


  unless ExtendedMetadataType.where(title:'study_conditions_emt', supported_type:'ExtendedMetadata').any?
    emt = ExtendedMetadataType.new(title: 'study_conditions_emt', supported_type:'ExtendedMetadata')
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'study_conditions', sample_attribute_type: string_type, description: "study_conditions", label: "study_conditions", required:true)
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'study_conditions_classification',sample_attribute_type: string_type, description: "study_conditions_classification", label: "study_conditions_classification")
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'study_conditions_classification_code',sample_attribute_type: string_type, description: "study_conditions_classification_code", label: "study_conditions_classification_code")
    emt.save!
  end

  unless ExtendedMetadataType.where(title:'study_design_emt', supported_type:'ExtendedMetadata').any?
    emt = ExtendedMetadataType.new(title: 'study_design_emt', supported_type:'ExtendedMetadata')
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'study_primary_design', required:true,
                                                                      sample_attribute_type: cv_type, sample_controlled_vocab: study_primary_design_cv)
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'study_conditions',
                                                                      sample_attribute_type:linked_extended_metadata_type_list, linked_extended_metadata_type: ExtendedMetadataType.where(title:'study_conditions_emt', supported_type:'ExtendedMetadata').first )
    emt.save!
  end



  unless ExtendedMetadataType.where(title:'My Study Metadata Example', supported_type:'Study').any?

    emt = ExtendedMetadataType.new(title: 'My Study Metadata Example', supported_type:'Study')

    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'title', # The attribute's identifier or name .
      required: true, # Indicates whether this attribute is mandatory for the associated metadata.
      sample_attribute_type: string_type, # Specifies the attribute type, here set to 'String'.
      description: 'the title of your study', # A brief description providing additional details about the attribute. By default, it is set to the empty string.
      label: 'study title' # The label to be displayed in the user interface, conveying the purpose of the attribute. By default, it is set to the value of the 'title' attribute."
    )

    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'description', required:true, sample_attribute_type: text_type )

    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'study_age', required:true, sample_attribute_type: int_type)
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'cholesterol_level', required:true, sample_attribute_type: float_type)
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'resource_type_general', required:true,
                                                                      sample_attribute_type: cv_type, sample_controlled_vocab: resource_type_general_cv)
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'study_start_date', required:true, sample_attribute_type: date_type)
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'study_start_time', required:true, sample_attribute_type: date_time_type)
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'study_end_date', sample_attribute_type: date_type)
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'study_end_time', sample_attribute_type: date_time_type)
    emt.extended_metadata_attributes <<  ExtendedMetadataAttribute.new(title: 'study_country', required:true, sample_attribute_type: cv_type_list, sample_controlled_vocab: study_country_cv)
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'resource_use_rights',
                                                                      sample_attribute_type: linked_extended_metadata_type, linked_extended_metadata_type: ExtendedMetadataType.where(title:'resource_use_rights_emt', supported_type:'ExtendedMetadata').first )
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'resource_role',
                                                                      sample_attribute_type: linked_extended_metadata_type_list, linked_extended_metadata_type: ExtendedMetadataType.where(title:'role_emt', supported_type:'ExtendedMetadata').first )
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'study_design',
                                                                      sample_attribute_type: linked_extended_metadata_type, linked_extended_metadata_type: ExtendedMetadataType.where(title:'study_design_emt', supported_type:'ExtendedMetadata').first )

    emt.save!
    puts 'My study metadata is created'
  end
end