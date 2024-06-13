string_attribute_type = SampleAttributeType.where(title:'String').first
data_file_attribute_type = SampleAttributeType.where(title:'Registered Data file').first
sop_attribute_type = SampleAttributeType.where(title:'Registered SOP').first

unless ExtendedMetadataType.where(title:'Test linking registered resources', supported_type:'Study').any?
  emt = ExtendedMetadataType.new(title: 'Test linking registered resources', supported_type:'Study')

  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'some text', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Linked SOP', property_type_id:'http://dummy_ontology.org/terms#linked_sop', sample_attribute_type: sop_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Linked Data file', property_type_id:'http://dummy_ontology.org/terms#linked_data_file', sample_attribute_type: data_file_attribute_type)

  emt.save!
  puts 'Test linking registered resources'
end