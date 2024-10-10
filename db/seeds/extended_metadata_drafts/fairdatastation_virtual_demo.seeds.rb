string_attribute_type = SampleAttributeType.where(title:'String').first

unless ExtendedMetadataType.where(title:'Fair Data Station Virtual Demo', supported_type:'Study').any?
  emt = ExtendedMetadataType.new(title: 'Fair Data Station Virtual Demo', supported_type:'Study')

  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Alias', pid:'http://fairbydesign.nl/ontology/alias', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Centre Name', pid:'http://fairbydesign.nl/ontology/center_name', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Centre Project Name', pid:'http://fairbydesign.nl/ontology/center_project_name', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'External Ids', pid:'http://fairbydesign.nl/ontology/external_ids', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Submission Accession', pid:'http://fairbydesign.nl/ontology/submission_accession', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Submission Alias', pid:'http://fairbydesign.nl/ontology/submission_alias', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Submission Lab Name', pid:'http://fairbydesign.nl/ontology/submission_lab_name', sample_attribute_type: string_attribute_type)

  emt.save!
  puts 'Fair Data Station Virtual Demo for Study'
end

unless ExtendedMetadataType.where(title:'Fair Data Station Virtual Demo', supported_type:'Assay').any?
  emt = ExtendedMetadataType.new(title: 'Fair Data Station Virtual Demo', supported_type:'Assay')

  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Facility', pid:'http://fairbydesign.nl/ontology/facility', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Forward Primer', pid:'http://fairbydesign.nl/ontology/forwardPrimer', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Instrument Model', pid:'http://fairbydesign.nl/ontology/instrument_model', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Library Selection', pid:'http://fairbydesign.nl/ontology/library_selection', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Library Source', pid:'http://fairbydesign.nl/ontology/library_source', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Library Strategy', pid:'http://fairbydesign.nl/ontology/library_strategy', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Package Name', pid:'http://fairbydesign.nl/ontology/packageName', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Platform', pid:'http://fairbydesign.nl/ontology/platform', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Primer Names', pid:'http://fairbydesign.nl/ontology/primerNames', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Protocol', pid:'http://fairbydesign.nl/ontology/protocol', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Reverse Primer', pid:'http://fairbydesign.nl/ontology/reversePrimer', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Target Subfragment', pid:'http://fairbydesign.nl/ontology/target_subfragment', sample_attribute_type: string_attribute_type)

  emt.save!
  puts 'Fair Data Station Virtual Demo for Assay'
end

unless ExtendedMetadataType.where(title:'Fair Data Station Indpensim', supported_type:'ObservationUnit').any?
  emt = ExtendedMetadataType.new(title: 'Fair Data Station Indpensim', supported_type:'ObservationUnit')

  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Brand', pid:'http://fairbydesign.nl/ontology/brand', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Fermentation', pid:'http://fairbydesign.nl/ontology/fermentation', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Volume', pid:'http://fairbydesign.nl/ontology/volume', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Scientific Name', pid:'http://gbol.life/0.1/scientificName', sample_attribute_type: string_attribute_type)
  emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(title: 'Organism', pid:'http://purl.uniprot.org/core/organism', sample_attribute_type: string_attribute_type)

  emt.save!
  puts 'Fair Data Station Observation Unit for Indpensim'
end

unless ExtendedMetadataType.where(title:'Fair Data Station Pichia', supported_type:'ObservationUnit').any?
  emt = ExtendedMetadataType.new(title: 'Fair Data Station Pichia', supported_type:'ObservationUnit',
    extended_metadata_attributes_attributes: [
      { title: 'Author', pid: 'http://fairbydesign.nl/ontology/author', sample_attribute_type: string_attribute_type},
      { title: 'Control action', pid: 'http://fairbydesign.nl/ontology/control_action', sample_attribute_type: string_attribute_type},
      { title: 'Control objective', pid: 'http://fairbydesign.nl/ontology/control_objective', sample_attribute_type: string_attribute_type},
      { title: 'Control type', pid: 'http://fairbydesign.nl/ontology/control_type', sample_attribute_type: string_attribute_type},
      { title: 'Date', pid: 'http://fairbydesign.nl/ontology/date', sample_attribute_type: string_attribute_type},
      { title: 'Operational mode', pid: 'http://fairbydesign.nl/ontology/operational_mode', sample_attribute_type: string_attribute_type},
      { title: 'Operational strategy', pid: 'http://fairbydesign.nl/ontology/operational_strategy', sample_attribute_type: string_attribute_type},
      { title: 'Promotor', pid: 'http://fairbydesign.nl/ontology/promoter', sample_attribute_type: string_attribute_type},
      { title: 'Protein', pid: 'http://fairbydesign.nl/ontology/protein', sample_attribute_type: string_attribute_type},
      { title: 'Published', pid: 'http://fairbydesign.nl/ontology/published', sample_attribute_type: string_attribute_type},
      { title: 'Strain', pid: 'http://fairbydesign.nl/ontology/strain', sample_attribute_type: string_attribute_type},
      { title: 'Substrate batch', pid: 'http://fairbydesign.nl/ontology/substrate_batch', sample_attribute_type: string_attribute_type},
      { title: 'Substrate fed batch', pid: 'http://fairbydesign.nl/ontology/substrate_fed-batch', sample_attribute_type: string_attribute_type},
      { title: 'Scientific name', pid: 'http://gbol.life/0.1/scientificName', sample_attribute_type: string_attribute_type}
    ]
  )
  emt.save!
  puts 'Fair Data Station Observation Unit for Pichia'
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