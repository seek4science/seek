unless ExtendedMetadataType.where(title:'Fair Data Station Virtual Demo', supported_type:'Study').any?
  emt = ExtendedMetadataType.new(title: 'Fair Data Station Virtual Demo', supported_type:'Study')

  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Centre Name', property_type_id:'http://fairbydesign.nl/ontology/center_name', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Centre Project Name', property_type_id:'http://fairbydesign.nl/ontology/center_project_name', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'External Ids', property_type_id:'http://fairbydesign.nl/ontology/external_ids', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Submission Accession', property_type_id:'http://fairbydesign.nl/ontology/submission_accession', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Submission Alias', property_type_id:'http://fairbydesign.nl/ontology/submission_alias', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Submission Lab Name', property_type_id:'http://fairbydesign.nl/ontology/submission_accession', sample_attribute_type: SampleAttributeType.where(title:'String').first)

  emt.save!
  puts 'Fair Data Station Virtual Demo'
end