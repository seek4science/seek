FactoryBot.define do
  # SampleType
  factory(:sample_type) do
    sequence(:title) { |n| "SampleType #{n}" }
    with_project_contributor
    #projects { [FactoryBot.build(:project)] }
  end
  
  factory(:patient_sample_type, parent: :sample_type) do
    title { 'Patient data' }
    after(:build) do |type|
      # Not sure why i have to explicitly add the sample_type association
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'full name', sample_attribute_type: FactoryBot.create(:full_name_sample_attribute_type), required: true, is_title: true, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'age', sample_attribute_type: FactoryBot.create(:age_sample_attribute_type), required: true, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'weight', sample_attribute_type: FactoryBot.create(:weight_sample_attribute_type), unit: Unit.find_or_create_by(symbol: 'g', comment: 'gram'),
                                              description: 'the weight of the patient', required: false, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'address', sample_attribute_type: FactoryBot.create(:address_sample_attribute_type), required: false, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'postcode', sample_attribute_type: FactoryBot.create(:postcode_sample_attribute_type), required: false, sample_type: type)
    end
  end
  
  factory(:simple_sample_type, parent: :sample_type) do
    sequence(:title) { |n| "Simple Sample Type #{n}" }
    after(:build) do |type|
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'the_title', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
    end
  end
  
  factory(:strain_sample_type, parent: :sample_type) do
    title { 'Strain type' }
    association :content_blob, factory: :strain_sample_data_content_blob
    uploaded_template { true }
    after(:build) do |type|
      type.sample_attributes << FactoryBot.build(:sample_attribute, template_column_index: 1, title: 'name', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, template_column_index: 2, title: 'seekstrain', sample_attribute_type: FactoryBot.create(:strain_sample_attribute_type), required: true, sample_type: type)
    end
  end
  
  factory(:data_file_sample_type, parent: :sample_type) do
    title { 'DataFile type' }
    after(:build) do |type|
      type.sample_attributes << FactoryBot.build(:data_file_sample_attribute, title:'data file', is_title: true, sample_type:type)
    end
  end
  
  factory(:optional_strain_sample_type, parent: :strain_sample_type) do
    after(:build) do |type|
      type.sample_attributes = [FactoryBot.build(:sample_attribute, template_column_index: 1, title: 'name', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, is_title: true, sample_type: type),
                                FactoryBot.build(:sample_attribute, template_column_index: 2, title: 'seekstrain', sample_attribute_type: FactoryBot.create(:strain_sample_attribute_type), required: false, sample_type: type)]
    end
  end
  
  factory(:apples_controlled_vocab_sample_type, parent: :sample_type) do
    sequence(:title) { |n| "apples controlled vocab sample type #{n}" }
    after(:build) do |type|
      type.sample_attributes << FactoryBot.build(:apples_controlled_vocab_attribute, title: 'apples', is_title: true, required: true, sample_type: type)
    end
  end
  
  factory(:apples_list_controlled_vocab_sample_type, parent: :sample_type) do
    sequence(:title) { |n| "apples list controlled vocab sample type #{n}" }
    after(:build) do |type|
      type.sample_attributes << FactoryBot.build(:apples_list_controlled_vocab_attribute, title: 'apples', is_title: true, required: true, sample_type: type)
    end
  end
  
  factory(:linked_sample_type, parent: :sample_type) do
    sequence(:title) { |n| "linked sample type #{n}" }
    after(:build) do |type|
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'title', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_sample_attribute, title: 'patient', linked_sample_type: FactoryBot.create(:patient_sample_type,projects:type.projects,contributor:type.contributor), required: true, sample_type: type)
    end
  end
  
  factory(:linked_sample_type_to_self, parent: :sample_type) do
    sequence(:title) { |n| "linked sample type #{n}" }
    after(:build) do |type|
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'title', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_sample_attribute, title: 'self', linked_sample_type: type, required: true, sample_type: type)
    end
  end
  
  factory(:source_sample_type, parent: :sample_type) do
    title { 'Library' }
    after(:build) do |type|
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'title', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'info', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: false, sample_type: type)
    end
  end
  
  factory(:linked_optional_sample_type, parent: :sample_type) do
    sequence(:title) { |n| "linked sample type #{n}" }
    after(:build) do |type|
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'title', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_sample_attribute, title: 'patient', linked_sample_type: FactoryBot.create(:patient_sample_type,project_ids:type.projects.collect(&:id)), required: false, sample_type: type)
    end
  end
  
  factory(:multi_linked_sample_type, parent: :sample_type) do
    sequence(:title) { |n| "multi linked sample type #{n}" }
    after(:build) do |type|
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'title', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_multi_sample_attribute, title: 'patient', linked_sample_type: FactoryBot.create(:patient_sample_type,projects:type.projects,contributor:type.contributor), required: true, sample_type: type)
    end
  end
  
  factory(:min_sample_type, parent: :sample_type) do
    title { 'A Minimal SampleType' }
    after(:build) do |type|
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'full_name', sample_attribute_type: FactoryBot.create(:full_name_sample_attribute_type), required: true, is_title: true, sample_type: type)
    end
  end
  
  factory(:max_sample_type, parent: :sample_type) do
    title { 'A Maximal SampleType' }
    description { 'A very new research' }
    assays { [FactoryBot.create(:public_assay)] }
    after(:build) do |type|
      # Not sure why i have to explicitly add the sample_type association
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'full_name', description: 'the persons full name', sample_attribute_type: FactoryBot.create(:full_name_sample_attribute_type), required: true, is_title: true, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'address', sample_attribute_type: FactoryBot.create(:address_sample_attribute_type), required: false, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'postcode', pid: 'dc:postcode', sample_attribute_type: FactoryBot.create(:postcode_sample_attribute_type), required: false, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'CAPITAL key', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type, title:'String'), required: false, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'apple', sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type), required: false, sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab), sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'apples', sample_attribute_type: FactoryBot.create(:cv_list_attribute_type), required: false, sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab), sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_multi_sample_attribute, title: 'patients', linked_sample_type: FactoryBot.create(:patient_sample_type), required: false, sample_type: type)
    end
    after(:create) do |type|
      type.annotate_with(['tag1', 'tag2'], 'sample_type_tag', type.contributor)
      type.save!
    end
  end
  factory(:sample_type_with_symbols, parent: :sample_type) do
    sequence(:title) { |n| "sample type with symbols #{n}" }
    after(:build) do |type|
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'title&', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'name ++##!', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, is_title: false, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'size range (bp)', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, is_title: false, sample_type: type)
    end
  end
  
  factory(:isa_source_sample_type, parent: :sample_type) do
    sequence(:title) { |n| "ISA Source #{n}" }
    after(:build) do |type|
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'Source Name', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, is_title: true, isa_tag_id: IsaTag.find_by_title("source").id, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'Source Characteristic 1', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, isa_tag_id: IsaTag.find_by_title("source_characteristic").id, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'Source Characteristic 2', sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type), required: true, isa_tag_id: IsaTag.find_by_title("source_characteristic").id, sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab), sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'Source Characteristic 3', sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type, title:'Ontology'), isa_tag_id: IsaTag.find_by_title("source_characteristic").id, sample_controlled_vocab: FactoryBot.create(:efo_ontology), pid: 'pid:pid', sample_type: type)
    end
  end
  
  factory(:isa_sample_collection_sample_type, parent: :sample_type) do
    transient do
      linked_sample_type { nil }
    end
    sequence(:title) { |n| "ISA sample collection #{n}" }
    after(:build) do |type, eval|
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'Input', sample_attribute_type: FactoryBot.create(:sample_multi_sample_attribute_type), linked_sample_type: eval.linked_sample_type, required: true, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'sample collection', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, isa_tag_id: IsaTag.find_by_title("protocol").id, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'sample collection parameter value 1', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, isa_tag_id: IsaTag.find_by_title("parameter_value").id, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'sample collection parameter value 2', sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type), isa_tag_id: IsaTag.find_by_title("parameter_value").id, sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab), sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'sample collection parameter value 3', sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type, title: 'Ontology'), isa_tag_id: IsaTag.find_by_title("parameter_value").id, sample_controlled_vocab: FactoryBot.create(:efo_ontology), pid: 'pid:pid', sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'Sample Name', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type),is_title: true, required: true, isa_tag_id: IsaTag.find_by_title("sample").id, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'sample characteristic 1', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, isa_tag_id: IsaTag.find_by_title("sample_characteristic").id, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'sample characteristic 2', sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type), isa_tag_id: IsaTag.find_by_title("sample_characteristic").id, sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab), sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'sample characteristic 3', sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type, title: 'Ontology'), isa_tag_id: IsaTag.find_by_title("sample_characteristic").id, sample_controlled_vocab: FactoryBot.create(:obi_ontology), pid: 'pid:pid', sample_type: type)
    end
  end
  
  factory(:isa_assay_sample_type, parent: :sample_type) do
    transient do
      linked_sample_type { nil }
    end
    sequence(:title) { |n| "ISA Assay #{n}" }
    after(:build) do |type, eval|
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'Input', sample_attribute_type: FactoryBot.create(:sample_multi_sample_attribute_type), linked_sample_type: eval.linked_sample_type, required: true, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'Protocol Assay 1', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, isa_tag_id: IsaTag.find_by_title("protocol").id, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'Assay 1 parameter value 1', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, isa_tag_id: IsaTag.find_by_title("parameter_value").id, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'Assay 1 parameter value 2', sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type), isa_tag_id: IsaTag.find_by_title("parameter_value").id, sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab), sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'Assay 1 parameter value 3', sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type, title: 'Ontology'), isa_tag_id: IsaTag.find_by_title("parameter_value").id, sample_controlled_vocab: FactoryBot.create(:obi_ontology), pid: 'pid:pid', sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'Extract Name', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, is_title: true, isa_tag_id: IsaTag.find_by_title("other_material").id, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'other material characteristic 1', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: true, isa_tag_id: IsaTag.find_by_title("other_material_characteristic").id, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'other material characteristic 2', sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type), isa_tag_id: IsaTag.find_by_title("other_material_characteristic").id, sample_controlled_vocab: FactoryBot.create(:apples_sample_controlled_vocab), sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'other material characteristic 3', sample_attribute_type: FactoryBot.create(:controlled_vocab_attribute_type, title: 'Ontology'), isa_tag_id: IsaTag.find_by_title("other_material_characteristic").id, sample_controlled_vocab: FactoryBot.create(:efo_ontology), pid: 'pid:pid', sample_type: type)
    end
  end
end
