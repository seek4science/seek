
unless CustomMetadataType.where(title:'MIAPPE metadata v1.1', supported_type:'Investigation').any?
  cmt = CustomMetadataType.new(title: 'MIAPPE metadata v1.1', supported_type:'Investigation')
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'id', required:true, sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'submission_date', sample_attribute_type: SampleAttributeType.where(title:'Date').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'license', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'miappe_version', required:true, sample_attribute_type: SampleAttributeType.where(title:'Integer').first)
  cmt.save!
  puts 'Seeded Investigation extended metadata for MIAPPE v1.1'
end

unless CustomMetadataType.where(title:'MIAPPE metadata v1.1', supported_type:'Study').any?
  cmt = CustomMetadataType.new(title: 'MIAPPE metadata v1.1', supported_type:'Study')
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'id', required:true, sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'study_start_date', required:true, sample_attribute_type: SampleAttributeType.where(title:'Date').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'study_end_date', sample_attribute_type: SampleAttributeType.where(title:'Date').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'contact_institution', required:true, sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'geographic_location_country', required:true, sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'experimental_site_name', required:true, sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'latitude', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'longitude', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'altitude', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'description_of_the_experimental_design', required:true, sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'type_of_experimental_design', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'observation_unit_level_hierarchy', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'observation_unit_description', required:true, sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'description_of_growth_facility', required:true, sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'type_of_growth_facility', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'cultural_practices', sample_attribute_type: SampleAttributeType.where(title:'String').first)

  cmt.save!
  puts 'Seeded Study extended metadata for MIAPPE v1.1'
end

unless CustomMetadataType.where(title:'MIAPPE metadata v1.1', supported_type:'Assay').any?
  cmt = CustomMetadataType.new(title: 'MIAPPE metadata v1.1', supported_type: 'Assay')
  cmt.custom_metadata_attributes << CustomMetadataAttribute.new(title: 'level', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  cmt.save!
  puts 'Seeded Assay extended metadata for MIAPPE v1.1'
end