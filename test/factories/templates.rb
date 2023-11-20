FactoryBot.define do
  # Template
  factory(:template) do
    sequence(:title) { |n| "Template #{n}" }
    level {"study source"}
    with_project_contributor
  end


  factory(:min_template, parent: :template) do
    title { 'A Minimal Template' }
    after(:build) do |template|
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'full_name', sample_attribute_type: FactoryBot.create(:full_name_sample_attribute_type), required: true, template: template, isa_tag_id: FactoryBot.create(:default_isa_tag).id)
    end
  end

  factory(:max_template, parent: :template) do
    title { 'A Maximal Template' }
    description { 'A very new research' }
    group { 'arrayexpress' }
    group_order { 4 }
    temporary_name { '4_arrayexpress_library_construction' }
    version { '1.2.0' }
    isa_config { 'genome_seq_default_v2015-07-02' }
    isa_measurement_type { 'transcription profiling' }
    isa_technology_type { 'transcription profiling' }
    repo_schema_id { 'transcription profiling' }
    organism { 'any' }
    level { 'assay' }

    after(:build) do |template|
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'full_name', sample_attribute_type: FactoryBot.create(:full_name_sample_attribute_type),
                   required: true, short_name: 'full_name short_name', description: 'full_name description', ontology_version:"1.1", template: template, isa_tag_id: FactoryBot.create(:default_isa_tag).id)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'address', sample_attribute_type: FactoryBot.create(:address_sample_attribute_type),
                   required: false, short_name: 'address short_name', description: 'address description', ontology_version:"2.1", template: template, isa_tag_id: FactoryBot.create(:default_isa_tag).id)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'postcode', sample_attribute_type: FactoryBot.create(:postcode_sample_attribute_type),
                   required: false, short_name: 'postcode short_name', description: 'postcode description', ontology_version:"4", template: template, isa_tag_id: FactoryBot.create(:default_isa_tag).id)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'CAPITAL key', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type, title:'String'),
                   required: false, short_name: 'CAPITAL key short_name', description: 'CAPITAL key description', ontology_version:"v0.0.9", template: template, isa_tag_id: FactoryBot.create(:default_isa_tag).id)
    end
  end

  factory(:apples_controlled_vocab_template, parent: :template) do
    sequence(:title) { |n| "apples controlled vocab template #{n}" }
    after(:build) do |template|
      template.template_attributes << FactoryBot.build(:apples_controlled_vocab_template_attribute, title: 'apples', isa_tag_id: FactoryBot.create(:default_isa_tag).id, required: true, template: template)
    end
  end

  # !!! If you change this template, apply the same changes to the isa_source_sample_type factory !!!
  # There are tests that rely on having identical Sample Type Attributes
  factory(:isa_source_template, parent: :template) do
    sequence(:title) { |n| "ISA Source Template #{n}" }
    level { 'study source' }
    after(:build) do |template|
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Source Name', isa_tag_id: FactoryBot.create(:source_isa_tag).id, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, is_title: true)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Source Characteristic 1', isa_tag_id: FactoryBot.create(:source_characteristic_isa_tag).id, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Source Characteristic 2', isa_tag_id: FactoryBot.create(:source_characteristic_isa_tag).id, sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type), required: true, sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab))
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Source Characteristic 3', isa_tag_id: FactoryBot.create(:source_characteristic_isa_tag).id, sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type, title:'Ontology'), sample_controlled_vocab: FactoryBot.create(:efo_ontology))
    end
  end

  # !!! If you change this template, apply the same changes to the isa_sample_collection_sample_type factory !!!
  # There are tests that rely on having identical Sample Type Attributes
  factory(:isa_sample_collection_template, parent: :template) do
    sequence(:title) { |n| "ISA Sample Collection Template #{n}" }
    level { 'study sample' }
    after(:build) do |template|
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Input', sample_attribute_type: FactoryBot.create(:sample_multi_sample_attribute_type), required: true)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'sample collection', isa_tag_id: FactoryBot.create(:protocol_isa_tag).id, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'sample collection parameter value 1', isa_tag_id: FactoryBot.create(:parameter_value_isa_tag).id, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'sample collection parameter value 2', isa_tag_id: FactoryBot.create(:parameter_value_isa_tag).id, sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type), sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab))
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'sample collection parameter value 3', isa_tag_id: FactoryBot.create(:parameter_value_isa_tag).id, sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type, title: 'Ontology'), sample_controlled_vocab: FactoryBot.create(:efo_ontology))
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Sample Name', isa_tag_id: FactoryBot.create(:sample_isa_tag).id, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type),is_title: true, required: true)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'sample characteristic 1', isa_tag_id: FactoryBot.create(:sample_characteristic_isa_tag).id, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'sample characteristic 2', isa_tag_id: FactoryBot.create(:sample_characteristic_isa_tag).id, sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type), sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab))
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'sample characteristic 3', isa_tag_id: FactoryBot.create(:sample_characteristic_isa_tag).id, sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type, title: 'Ontology'), sample_controlled_vocab: FactoryBot.create(:obi_ontology))
    end
  end

  # !!! If you change this template, apply the same changes to the isa_assay_material_sample_type factory !!!
  # There are tests that rely on having identical Sample Type Attributes
  factory(:isa_assay_material_template, parent: :template) do
    sequence(:title) { |n| "ISA Assay Material Template #{n}" }
    level { 'assay - material' }
    after(:build) do |template|
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Input', sample_attribute_type: FactoryBot.create(:sample_multi_sample_attribute_type), required: true)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Protocol Assay 1', isa_tag_id: FactoryBot.create(:protocol_isa_tag).id, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Assay 1 parameter value 1', isa_tag_id: FactoryBot.create(:parameter_value_isa_tag).id, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Assay 1 parameter value 2', isa_tag_id: FactoryBot.create(:parameter_value_isa_tag).id, sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type), sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab))
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Assay 1 parameter value 3', isa_tag_id: FactoryBot.create(:parameter_value_isa_tag).id, sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type, title: 'Ontology'), sample_controlled_vocab: FactoryBot.create(:obi_ontology))
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Extract Name', isa_tag_id: FactoryBot.create(:other_material_isa_tag).id, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, is_title: true)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'other material characteristic 1', isa_tag_id: FactoryBot.create(:other_material_characteristic_isa_tag).id, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'other material characteristic 2', isa_tag_id: FactoryBot.create(:other_material_characteristic_isa_tag).id, sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type), sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab))
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'other material characteristic 3', isa_tag_id: FactoryBot.create(:other_material_characteristic_isa_tag).id, sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type, title: 'Ontology'), sample_controlled_vocab: FactoryBot.create(:efo_ontology))
    end
  end

  # !!! If you change this template, apply the same changes to the isa_assay_data_file_sample_type factory !!!
  # There are tests that rely on having identical Sample Type Attributes
  factory(:isa_assay_data_file_template, parent: :template) do
    sequence(:title) { |n| "ISA Assay Data File Template #{n}" }
    level { 'assay - data file' }
    after(:build) do |template|
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Input', sample_attribute_type: FactoryBot.create(:sample_multi_sample_attribute_type), required: true)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Protocol Assay 2', isa_tag_id: FactoryBot.create(:protocol_isa_tag).id, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Assay 2 parameter value 1', isa_tag_id: FactoryBot.create(:parameter_value_isa_tag).id, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Assay 2 parameter value 2', isa_tag_id: FactoryBot.create(:parameter_value_isa_tag).id, sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type), sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab))
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Assay 2 parameter value 3', isa_tag_id: FactoryBot.create(:parameter_value_isa_tag).id, sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type, title: 'Ontology'), sample_controlled_vocab: FactoryBot.create(:obi_ontology))
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'File Name', isa_tag_id: FactoryBot.create(:data_file_isa_tag).id, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, is_title: true)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Data file comment 1', isa_tag_id: FactoryBot.create(:data_file_comment_isa_tag).id, sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true)
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Data file comment 2', isa_tag_id: FactoryBot.create(:data_file_comment_isa_tag).id, sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type), sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab))
      template.template_attributes << FactoryBot.build(:template_attribute, title: 'Data file comment 3', isa_tag_id: FactoryBot.create(:data_file_comment_isa_tag).id, sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type, title: 'Ontology'), sample_controlled_vocab: FactoryBot.create(:efo_ontology))
    end
  end
end
