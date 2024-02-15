
unless ExtendedMetadataType.where(title:'MIAPPE metadata v1.1', supported_type:'Investigation').any?
  emt = ExtendedMetadataType.new(title: 'MIAPPE metadata v1.1', supported_type:'Investigation')
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'id', required:true, sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'submission_date', sample_attribute_type: SampleAttributeType.where(title:'Date').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'license', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'miappe_version', required:true, sample_attribute_type: SampleAttributeType.where(title:'Integer').first)
  emt.save!
  puts 'Seeded Investigation extended metadata for MIAPPE v1.1'
end

unless ExtendedMetadataType.where(title:'MIAPPE metadata v1.1', supported_type:'Study').any?
  emt = ExtendedMetadataType.new(title: 'MIAPPE metadata v1.1', supported_type:'Study')
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'id', required:true, sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'study_start_date', required:true, sample_attribute_type: SampleAttributeType.where(title:'Date').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'study_end_date', sample_attribute_type: SampleAttributeType.where(title:'Date').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'contact_institution', required:true, sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'geographic_location_country', required:true, sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'experimental_site_name', required:true, sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'latitude', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'longitude', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'altitude', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'description_of_the_experimental_design', required:true, sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'type_of_experimental_design', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'observation_unit_level_hierarchy', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'observation_unit_description', required:true, sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'description_of_growth_facility', required:true, sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'type_of_growth_facility', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'cultural_practices', sample_attribute_type: SampleAttributeType.where(title:'String').first)

  emt.save!
  puts 'Seeded Study extended metadata for MIAPPE v1.1'
end

unless ExtendedMetadataType.where(title:'MIAPPE metadata v1.1', supported_type:'Assay').any?
  emt = ExtendedMetadataType.new(title: 'MIAPPE metadata v1.1', supported_type: 'Assay')
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'level', sample_attribute_type: SampleAttributeType.where(title:'String').first)
  emt.save!
  puts 'Seeded Assay extended metadata for MIAPPE v1.1'
end