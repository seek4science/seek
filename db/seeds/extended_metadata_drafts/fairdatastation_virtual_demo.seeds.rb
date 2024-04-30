string_attribute_type = SampleAttributeType.where(title:'String').first

unless ExtendedMetadataType.where(title:'Fair Data Station Virtual Demo', supported_type:'Study').any?
  emt = ExtendedMetadataType.new(title: 'Fair Data Station Virtual Demo', supported_type:'Study')

  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Alias', property_type_id:'http://fairbydesign.nl/ontology/alias', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Centre Name', property_type_id:'http://fairbydesign.nl/ontology/center_name', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Centre Project Name', property_type_id:'http://fairbydesign.nl/ontology/center_project_name', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'External Ids', property_type_id:'http://fairbydesign.nl/ontology/external_ids', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Submission Accession', property_type_id:'http://fairbydesign.nl/ontology/submission_accession', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Submission Alias', property_type_id:'http://fairbydesign.nl/ontology/submission_alias', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Submission Lab Name', property_type_id:'http://fairbydesign.nl/ontology/submission_lab_name', sample_attribute_type: string_attribute_type)

  emt.save!
  puts 'Fair Data Station Virtual Demo for Study'
end

unless ExtendedMetadataType.where(title:'Fair Data Station Virtual Demo', supported_type:'Assay').any?
  emt = ExtendedMetadataType.new(title: 'Fair Data Station Virtual Demo', supported_type:'Assay')

  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Facility', property_type_id:'http://fairbydesign.nl/ontology/facility', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Forward Primer', property_type_id:'http://fairbydesign.nl/ontology/forwardPrimer', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Instrument Model', property_type_id:'http://fairbydesign.nl/ontology/instrument_model', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Library Selection', property_type_id:'http://fairbydesign.nl/ontology/library_selection', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Library Source', property_type_id:'http://fairbydesign.nl/ontology/library_source', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Library Strategy', property_type_id:'http://fairbydesign.nl/ontology/library_strategy', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Package Name', property_type_id:'http://fairbydesign.nl/ontology/packageName', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Platform', property_type_id:'http://fairbydesign.nl/ontology/platform', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Primer Names', property_type_id:'http://fairbydesign.nl/ontology/primerNames', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Protocol', property_type_id:'http://fairbydesign.nl/ontology/protocol', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Reverse Primer', property_type_id:'http://fairbydesign.nl/ontology/reversePrimer', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Target Subfragment', property_type_id:'http://fairbydesign.nl/ontology/target_subfragment', sample_attribute_type: string_attribute_type)

  emt.save!
  puts 'Fair Data Station Virtual Demo for Assay'
end

unless ExtendedMetadataType.where(title:'Fair Data Station Indpensim', supported_type:'ObservationUnit').any?
  emt = ExtendedMetadataType.new(title: 'Fair Data Station Indpensim', supported_type:'ObservationUnit')

  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Brand', property_type_id:'http://fairbydesign.nl/ontology/brand', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Fermentation', property_type_id:'http://fairbydesign.nl/ontology/fermentation', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Volume', property_type_id:'http://fairbydesign.nl/ontology/volume', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Scientific Name', property_type_id:'http://gbol.life/0.1/scientificName', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Organism', property_type_id:'http://purl.uniprot.org/core/organism', sample_attribute_type: string_attribute_type)

  emt.save!
  puts 'Fair Data Station Indpensim for Observation Unit'
end

virtual_demo_sample_type = SampleType.where(title: 'Fair Data Station Virtual Demo').first_or_initialize(
  project_ids: [Project.first.id],
  contributor: Person.first,
  sample_attributes_attributes: [
    { title: 'Title', sample_attribute_type: string_attribute_type, required: true, is_title: true },
    { title: 'Description', sample_attribute_type: string_attribute_type },
    { title: 'art_drugs_current', pid:'http://fairbydesign.nl/ontology/art_drugs_current', sample_attribute_type: string_attribute_type },
    { title: 'art_duration_at baseline_months', pid:'http://fairbydesign.nl/ontology/art_duration_at_baseline_months', sample_attribute_type: string_attribute_type },
    { title: 'geo loc name', pid:'http://fairbydesign.nl/ontology/geo_loc_name', sample_attribute_type: string_attribute_type },
    { title: 'hiv risk exposure', pid:'http://fairbydesign.nl/ontology/hiv_risk_exposure', sample_attribute_type: string_attribute_type },
    { title: 'host', pid:'http://fairbydesign.nl/ontology/host', sample_attribute_type: string_attribute_type },
    { title: 'log vl', pid:'http://fairbydesign.nl/ontology/log_vl', sample_attribute_type: string_attribute_type },
    { title: 'marital status', pid:'http://fairbydesign.nl/ontology/marital_status', sample_attribute_type: string_attribute_type },
    { title: 'occupation', pid:'http://fairbydesign.nl/ontology/occupation', sample_attribute_type: string_attribute_type },
    { title: 'viral_load (copies/ml)', pid:'http://fairbydesign.nl/ontology/viral_load_copies_ml', sample_attribute_type: string_attribute_type },
    { title: 'scientific name', pid:'http://gbol.life/0.1/scientificName', sample_attribute_type: string_attribute_type },
    { title: 'organism', pid:'http://purl.uniprot.org/core/organism', sample_attribute_type: string_attribute_type }
  ]
)

if virtual_demo_sample_type.valid?
  disable_authorization_checks do
    virtual_demo_sample_type.save!
  end

  puts "Fair Data Station Virtual Demo Sample Type"
else
  puts virtual_demo_sample_type.errors.full_messages
end