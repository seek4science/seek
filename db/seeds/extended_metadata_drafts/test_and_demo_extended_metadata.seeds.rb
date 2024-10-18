string_attribute_type = SampleAttributeType.where(title:'String').first
data_file_attribute_type = SampleAttributeType.where(title:'Registered Data file').first
sop_attribute_type = SampleAttributeType.where(title:'Registered SOP').first

unless ExtendedMetadataType.where(title:'Test linking registered resources', supported_type:'Study').any?
  emt = ExtendedMetadataType.new(title: 'Test linking registered resources', supported_type:'Study')

  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'some text', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Linked SOP', pid:'http://dummy_ontology.org/terms#linked_sop', sample_attribute_type: sop_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Linked Data file', pid:'http://dummy_ontology.org/terms#linked_data_file', sample_attribute_type: data_file_attribute_type)

  emt.save!
  puts 'Test linking registered resources'
end


# fair data station simple seek test case

unless ExtendedMetadataType.where(title: 'FAIR Data Station Investigation Test Case', supported_type: 'Investigation').any?
  emt = ExtendedMetadataType.new(title: 'FAIR Data Station Investigation Test Case', supported_type: 'Investigation',
                                 extended_metadata_attributes_attributes: [
                                   { title: 'Associated publication', pid: 'http://fairbydesign.nl/ontology/associated_publication', sample_attribute_type: string_attribute_type }
                                 ])
  emt.save!
  puts "Created #{emt.title}"
end

unless ExtendedMetadataType.where(title: 'FAIR Data Station Study Test Case', supported_type: 'Study').any?
  emt = ExtendedMetadataType.new(title: 'FAIR Data Station Study Test Case', supported_type: 'Study',
                                 extended_metadata_attributes_attributes: [
                                   { title: 'End date of Study', pid: 'http://fairbydesign.nl/ontology/end_date_of_study', sample_attribute_type: string_attribute_type },
                                   { title: 'Start date of Study', pid: 'http://fairbydesign.nl/ontology/start_date_of_study', sample_attribute_type: string_attribute_type },
                                   { title: 'Experimental site name', pid: 'http://fairbydesign.nl/ontology/experimental_site_name', sample_attribute_type: string_attribute_type }
                                 ])
  emt.save!
  puts "Created #{emt.title}"
end

unless ExtendedMetadataType.where(title: 'FAIR Data Station ObservationUnit Test Case', supported_type: 'ObservationUnit').any?
  emt = ExtendedMetadataType.new(title: 'FAIR Data Station ObservationUnit Test Case', supported_type: 'ObservationUnit',
                                 extended_metadata_attributes_attributes: [
                                   { title: 'Birth weight', pid: 'http://fairbydesign.nl/ontology/birth_weight', sample_attribute_type: string_attribute_type },
                                   { title: 'Date of birth', pid: 'http://fairbydesign.nl/ontology/date_of_birth', sample_attribute_type: string_attribute_type },
                                   { title: 'Gender', pid: 'https://w3id.org/mixs/0000811', sample_attribute_type: string_attribute_type }
                                 ])
  emt.save!
  puts "Created #{emt.title}"
end

unless ExtendedMetadataType.where(title: 'FAIR Data Station Assay Test Case', supported_type: 'Assay').any?
  emt = ExtendedMetadataType.new(title: 'FAIR Data Station Assay Test Case', supported_type: 'Assay',
                                 extended_metadata_attributes_attributes: [
                                   { title: 'Facility', pid: 'http://fairbydesign.nl/ontology/facility', sample_attribute_type: string_attribute_type },
                                   { title: 'Protocol', pid: 'http://fairbydesign.nl/ontology/protocol', sample_attribute_type: string_attribute_type }
                                 ])
  emt.save!
  puts "Created #{emt.title}"
end

unless SampleType.where(title: 'Fair Data Station SampleType Test Case').any?
  sample_type = SampleType.new(title: 'Fair Data Station SampleType Test Case',
                               project_ids: [Project.first.id],
                               contributor: Person.first,
                               sample_attributes_attributes: [
                                 { title: 'Title', sample_attribute_type: string_attribute_type, required: true, is_title: true },
                                 { title: 'Description', sample_attribute_type: string_attribute_type },
                                 { title: 'Bio safety level', pid: 'http://fairbydesign.nl/ontology/biosafety_level', sample_attribute_type: string_attribute_type },
                                 { title: 'Scientific name', pid: 'http://gbol.life/0.1/scientificName', sample_attribute_type: string_attribute_type },
                                 { title: 'Organism ncbi id', pid: 'http://purl.uniprot.org/core/organism', sample_attribute_type: string_attribute_type },
                                 { title: 'Collection date', pid: 'https://w3id.org/mixs/0000011', sample_attribute_type: string_attribute_type }
                               ])
  disable_authorization_checks do
    sample_type.save!
    puts "Created #{sample_type.title}"
  end
end

