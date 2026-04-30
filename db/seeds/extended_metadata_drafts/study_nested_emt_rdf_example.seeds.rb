string_type = SampleAttributeType.find_or_initialize_by(title: 'String')
string_type.update(base_type: Seek::Samples::BaseType::STRING)

text_type = SampleAttributeType.find_or_initialize_by(title: 'Text')
text_type.update(base_type: Seek::Samples::BaseType::TEXT)

integer_type = SampleAttributeType.find_or_initialize_by(title: 'Integer')
integer_type.update(base_type: Seek::Samples::BaseType::INTEGER)

float_type = SampleAttributeType.find_or_initialize_by(title: 'Float')
float_type.update(base_type: Seek::Samples::BaseType::FLOAT)

boolean_type = SampleAttributeType.find_or_initialize_by(title: 'Boolean')
boolean_type.update(base_type: Seek::Samples::BaseType::BOOLEAN)

date_type = SampleAttributeType.find_or_initialize_by(title: 'Date')
date_type.update(base_type: Seek::Samples::BaseType::DATE)

datetime_type = SampleAttributeType.find_or_initialize_by(title: 'DateTime')
datetime_type.update(base_type: Seek::Samples::BaseType::DATE_TIME)

linked_type = SampleAttributeType.find_or_initialize_by(title: 'Linked Extended Metadata')
linked_type.update(base_type: Seek::Samples::BaseType::LINKED_EXTENDED_METADATA)

linked_multi_type = SampleAttributeType.find_or_initialize_by(title: 'Linked Extended Metadata (multiple)')
linked_multi_type.update(base_type: Seek::Samples::BaseType::LINKED_EXTENDED_METADATA_MULTI)

disable_authorization_checks do
  # Inner EMT: a time period with typed date endpoints
  unless ExtendedMetadataType.where(title: 'study_rdf_example_period', supported_type: 'ExtendedMetadata').any?
    period_emt = ExtendedMetadataType.new(title: 'study_rdf_example_period', supported_type: 'ExtendedMetadata')
    period_emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'start_date',
      pid: 'http://schema.org/startDate',
      sample_attribute_type: date_type
    )
    period_emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'end_date',
      pid: 'http://schema.org/endDate',
      sample_attribute_type: date_type
    )
    period_emt.save!
    puts 'Created study_rdf_example_period EMT'
  end

  # Inner EMT: a contact person (used as a multi-linked attribute)
  unless ExtendedMetadataType.where(title: 'study_rdf_example_contact', supported_type: 'ExtendedMetadata').any?
    contact_emt = ExtendedMetadataType.new(title: 'study_rdf_example_contact', supported_type: 'ExtendedMetadata')
    contact_emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'name',
      pid: 'http://xmlns.com/foaf/0.1/name',
      sample_attribute_type: string_type
    )
    contact_emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'email',
      pid: 'http://xmlns.com/foaf/0.1/mbox',
      sample_attribute_type: string_type
    )
    contact_emt.save!
    puts 'Created study_rdf_example_contact EMT'
  end

  # Outer Study EMT: one attribute per scalar base type + a nested period + multi-linked contacts
  unless ExtendedMetadataType.where(title: 'study_rdf_example', supported_type: 'Study').any?
    period_emt  = ExtendedMetadataType.find_by(title: 'study_rdf_example_period',  supported_type: 'ExtendedMetadata')
    contact_emt = ExtendedMetadataType.find_by(title: 'study_rdf_example_contact', supported_type: 'ExtendedMetadata')

    emt = ExtendedMetadataType.new(title: 'study_rdf_example', supported_type: 'Study')

    # String → plain xsd:string literal
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'study_label',
      pid: 'http://schema.org/name',
      sample_attribute_type: string_type
    )

    # Text → plain xsd:string literal
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'study_abstract',
      pid: 'http://schema.org/abstract',
      sample_attribute_type: text_type
    )

    # Integer → xsd:integer
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'participant_count',
      pid: 'http://schema.org/numberOfItems',
      sample_attribute_type: integer_type
    )

    # Float → xsd:double
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'success_rate',
      pid: 'http://fairbydesign.nl/ontology/successRate',
      sample_attribute_type: float_type
    )

    # Boolean → xsd:boolean
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'randomized',
      pid: 'http://schema.org/isPartOf',
      sample_attribute_type: boolean_type
    )

    # Date → xsd:date
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'registration_date',
      pid: 'http://schema.org/dateCreated',
      sample_attribute_type: date_type
    )

    # DateTime → xsd:dateTime
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'last_updated',
      pid: 'http://schema.org/dateModified',
      sample_attribute_type: datetime_type
    )

    # LinkedExtendedMetadata → single blank node with typed date children
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'collection_period',
      pid: 'http://schema.org/temporalCoverage',
      sample_attribute_type: linked_type,
      linked_extended_metadata_type: period_emt
    )

    # LinkedExtendedMetadataMulti → one blank node per contact person
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
      title: 'contact_persons',
      pid: 'http://schema.org/contributor',
      sample_attribute_type: linked_multi_type,
      linked_extended_metadata_type: contact_emt
    )

    emt.save!
    puts 'Created study_rdf_example EMT'
  end
end
# rubocop:enable Metrics/BlockLength
