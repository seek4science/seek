
unless CustomMetadataType.where(title:'IBISBA project 0.1', supported_type:'Project').any?
  cmt = CustomMetadataType.new(title: 'IBISBA project 0.1', supported_type:'Project')
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'ibisba_contact', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'scheduled_start_date', sample_attribute_type: SampleAttributeType.where(title:'Date').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'scheduled_finish_date', sample_attribute_type: SampleAttributeType.where(title:'Date').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'actual_start_date', sample_attribute_type: SampleAttributeType.where(title:'Date').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'actual_finish_date', sample_attribute_type: SampleAttributeType.where(title:'Date').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'status', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.save!
  puts 'Seeded Project extended metadata for IBISBA project 0.1'
end

unless CustomMetadataType.where(title:'IBISBA service 0.1', supported_type:'Assay').any?
  cmt = CustomMetadataType.new(title: 'IBISBA service 0.1', supported_type:'Assay')
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'service_contact', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'scheduled_start_date', sample_attribute_type: SampleAttributeType.where(title:'Date').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'scheduled_finish_date', sample_attribute_type: SampleAttributeType.where(title:'Date').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'actual_start_date', sample_attribute_type: SampleAttributeType.where(title:'Date').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'actual_finish_date', sample_attribute_type: SampleAttributeType.where(title:'Date').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'status', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.save!
  puts 'Seeded Assay extended metadata for IBISBA service 0.1'
end

