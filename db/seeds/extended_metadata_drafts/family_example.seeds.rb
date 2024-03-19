cv_type = SampleAttributeType.find_or_initialize_by(title: 'Controlled Vocabulary')
cv_type.update(base_type: Seek::Samples::BaseType::CV)

cv_type_list = SampleAttributeType.find_or_initialize_by(title: 'Controlled Vocabulary List')
cv_type_list.update(base_type: Seek::Samples::BaseType::CV_LIST)


def create_sample_controlled_vocab_terms_attributes(array)
  attributes = []
  array.each do |type|
    attributes << { label: type }
  end
  attributes
end


disable_authorization_checks do

  # Define the inner extended metadata type 'person' with attributes 'first_name' and 'last_name'.
  # The 'supported_type' is set to 'ExtendedMetadata' to denote it as the inner extended metadata type.
  #
  unless ExtendedMetadataType.where(title:'person', supported_type:'ExtendedMetadata').any?
    emt = ExtendedMetadataType.new(title: 'person', supported_type:'ExtendedMetadata')
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'first_name', sample_attribute_type: SampleAttributeType.where(title:'String').first)
    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'last_name', sample_attribute_type: SampleAttributeType.where(title:'String').first)
    emt.save!
  end

  # Define the extended metadata type 'family', which contains the nested extended metadata attributes
  unless ExtendedMetadataType.where(title:'family', supported_type:'Investigation').any?
    emt = ExtendedMetadataType.new(title: 'family', supported_type:'Investigation')

    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'dad',
                                                                  sample_attribute_type: SampleAttributeType.where(title:'Linked Extended Metadata').first, linked_extended_metadata_type: ExtendedMetadataType.where(title:'person', supported_type:'ExtendedMetadata').first )

    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'mom',
                                                                  sample_attribute_type: SampleAttributeType.where(title:'Linked Extended Metadata').first, linked_extended_metadata_type: ExtendedMetadataType.where(title:'person', supported_type:'ExtendedMetadata').first )

    emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'child',
                                                                  sample_attribute_type: SampleAttributeType.where(title:'Linked Extended Metadata (multiple)').first, linked_extended_metadata_type: ExtendedMetadataType.where(title:'person', supported_type:'ExtendedMetadata').first )


    emt.save!
    puts 'Family metadata'
  end

end

