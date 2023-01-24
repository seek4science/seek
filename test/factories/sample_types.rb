# SampleType
Factory.define(:sample_type) do |f|
  f.sequence(:title) { |n| "SampleType #{n}" }
  f.with_project_contributor
  #f.projects { [Factory.build(:project)] }
end

Factory.define(:patient_sample_type, parent: :sample_type) do |f|
  f.title 'Patient data'
  f.after_build do |type|
    # Not sure why i have to explicitly add the sample_type association
    type.sample_attributes << Factory.build(:sample_attribute, title: 'full name', sample_attribute_type: Factory(:full_name_sample_attribute_type), required: true, is_title: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'age', sample_attribute_type: Factory(:age_sample_attribute_type), required: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'weight', sample_attribute_type: Factory(:weight_sample_attribute_type), unit: Unit.find_or_create_by(symbol: 'g', comment: 'gram'),
                                            description: 'the weight of the patient', required: false, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'address', sample_attribute_type: Factory(:address_sample_attribute_type), required: false, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'postcode', sample_attribute_type: Factory(:postcode_sample_attribute_type), required: false, sample_type: type)
  end
end

Factory.define(:simple_sample_type, parent: :sample_type) do |f|
  f.sequence(:title) { |n| "Simple Sample Type #{n}" }
  f.after_build do |type|
    type.sample_attributes << Factory.build(:sample_attribute, title: 'the_title', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
  end
end

Factory.define(:strain_sample_type, parent: :sample_type) do |f|
  f.title 'Strain type'
  f.association :content_blob, factory: :strain_sample_data_content_blob
  f.uploaded_template true
  f.after_build do |type|
    type.sample_attributes << Factory.build(:sample_attribute, template_column_index: 1, title: 'name', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, template_column_index: 2, title: 'seekstrain', sample_attribute_type: Factory(:strain_sample_attribute_type), required: true, sample_type: type)
  end
end

Factory.define(:data_file_sample_type, parent: :sample_type) do |f|
  f.title 'DataFile type'
  f.after_build do |type|
    type.sample_attributes << Factory.build(:data_file_sample_attribute, title:'data file', is_title: true, sample_type:type)
  end
end

Factory.define(:optional_strain_sample_type, parent: :strain_sample_type) do |f|
  f.after_build do |type|
    type.sample_attributes = [Factory.build(:sample_attribute, template_column_index: 1, title: 'name', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, sample_type: type),
                              Factory.build(:sample_attribute, template_column_index: 2, title: 'seekstrain', sample_attribute_type: Factory(:strain_sample_attribute_type), required: false, sample_type: type)]
  end
end

Factory.define(:apples_controlled_vocab_sample_type, parent: :sample_type) do |f|
  f.sequence(:title) { |n| "apples controlled vocab sample type #{n}" }
  f.after_build do |type|
    type.sample_attributes << Factory.build(:apples_controlled_vocab_attribute, title: 'apples', is_title: true, required: true, sample_type: type)
  end
end

Factory.define(:apples_list_controlled_vocab_sample_type, parent: :sample_type) do |f|
  f.sequence(:title) { |n| "apples list controlled vocab sample type #{n}" }
  f.after_build do |type|
    type.sample_attributes << Factory.build(:apples_list_controlled_vocab_attribute, title: 'apples', is_title: true, required: true, sample_type: type)
  end
end

Factory.define(:linked_sample_type, parent: :sample_type) do |f|
  f.sequence(:title) { |n| "linked sample type #{n}" }
  f.after_build do |type|
    type.sample_attributes << Factory.build(:sample_attribute, title: 'title', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_sample_attribute, title: 'patient', linked_sample_type: Factory(:patient_sample_type,projects:type.projects,contributor:type.contributor), required: true, sample_type: type)
  end
end

Factory.define(:linked_sample_type_to_self, parent: :sample_type) do |f|
  f.sequence(:title) { |n| "linked sample type #{n}" }
  f.after_build do |type|
    type.sample_attributes << Factory.build(:sample_attribute, title: 'title', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_sample_attribute, title: 'self', linked_sample_type: type, required: true, sample_type: type)
  end
end

Factory.define(:source_sample_type, parent: :sample_type) do |f|
  f.title 'Library'
  f.after_build do |type|
    type.sample_attributes << Factory.build(:sample_attribute, title: 'title', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'info', sample_attribute_type: Factory(:string_sample_attribute_type), required: false, sample_type: type)
  end
end

Factory.define(:linked_optional_sample_type, parent: :sample_type) do |f|
  f.sequence(:title) { |n| "linked sample type #{n}" }
  f.after_build do |type|
    type.sample_attributes << Factory.build(:sample_attribute, title: 'title', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_sample_attribute, title: 'patient', linked_sample_type: Factory(:patient_sample_type,project_ids:type.projects.collect(&:id)), required: false, sample_type: type)
  end
end

Factory.define(:multi_linked_sample_type, parent: :sample_type) do |f|
  f.sequence(:title) { |n| "multi linked sample type #{n}" }
  f.after_build do |type|
    type.sample_attributes << Factory.build(:sample_attribute, title: 'title', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_multi_sample_attribute, title: 'patient', linked_sample_type: Factory(:patient_sample_type,projects:type.projects,contributor:type.contributor), required: true, sample_type: type)
  end
end

Factory.define(:min_sample_type, parent: :sample_type) do |f|
  f.title 'A Minimal SampleType'
  f.after_build do |type|
    type.sample_attributes << Factory.build(:sample_attribute, title: 'full_name', sample_attribute_type: Factory(:full_name_sample_attribute_type), required: true, is_title: true, sample_type: type)
  end
end

Factory.define(:max_sample_type, parent: :sample_type) do |f|
  f.title 'A Maximal SampleType'
  f.description 'A very new research'
  f.assays { [Factory(:public_assay)] }
  f.after_build do |type|
    # Not sure why i have to explicitly add the sample_type association
    type.sample_attributes << Factory.build(:sample_attribute, title: 'full_name', description: 'the persons full name', sample_attribute_type: Factory(:full_name_sample_attribute_type), required: true, is_title: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'address', sample_attribute_type: Factory(:address_sample_attribute_type), required: false, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'postcode', pid: 'dc:postcode', sample_attribute_type: Factory(:postcode_sample_attribute_type), required: false, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'CAPITAL key', sample_attribute_type: Factory(:string_sample_attribute_type, title:'String'), required: false, sample_type: type)
  end
  f.after_create do |type|
    type.annotate_with(['tag1', 'tag2'], 'sample_type_tag', type.contributor)
    type.save!
  end
end
Factory.define(:sample_type_with_symbols, parent: :sample_type) do |f|
  f.sequence(:title) { |n| "sample type with symbols #{n}" }
  f.after_build do |type|
    type.sample_attributes << Factory.build(:sample_attribute, title: 'title&', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'name ++##!', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: false, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'size range (bp)', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: false, sample_type: type)
  end
end

Factory.define(:isa_source_sample_type, parent: :sample_type) do |f|
  f.sequence(:title) { |n| "ISA Source #{n}" }
  f.after_build do |type|
    type.sample_attributes << Factory.build(:sample_attribute, title: 'Source Name', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, isa_tag_id: IsaTag.find_by_title("source").id, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'Source Characteristic 1', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, isa_tag_id: IsaTag.find_by_title("source_characteristic").id, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'Source Characteristic 2', sample_attribute_type: Factory(:controlled_vocab_attribute_type), required: true, isa_tag_id: IsaTag.find_by_title("source_characteristic").id, sample_controlled_vocab: Factory(:apples_sample_controlled_vocab), sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'Source Characteristic 3', sample_attribute_type: Factory(:controlled_vocab_attribute_type, title:'Ontology'), isa_tag_id: IsaTag.find_by_title("source_characteristic").id, sample_controlled_vocab: Factory(:efo_ontology), pid: 'pid:pid', sample_type: type)
  end
end

Factory.define(:isa_sample_collection_sample_type, parent: :sample_type) do |f|
  f.ignore do
    linked_sample_type nil
  end
  f.sequence(:title) { |n| "ISA sample collection #{n}" }
  f.after_build do |type, eval|
    type.sample_attributes << Factory.build(:sample_attribute, title: 'Input', sample_attribute_type: Factory(:sample_multi_sample_attribute_type), linked_sample_type: eval.linked_sample_type, required: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'sample collection', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, isa_tag_id: IsaTag.find_by_title("protocol").id, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'sample collection parameter value 1', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, isa_tag_id: IsaTag.find_by_title("parameter_value").id, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'sample collection parameter value 2', sample_attribute_type: Factory(:controlled_vocab_attribute_type), isa_tag_id: IsaTag.find_by_title("parameter_value").id, sample_controlled_vocab: Factory(:apples_sample_controlled_vocab), sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'sample collection parameter value 3', sample_attribute_type: Factory(:controlled_vocab_attribute_type, title: 'Ontology'), isa_tag_id: IsaTag.find_by_title("parameter_value").id, sample_controlled_vocab: Factory(:efo_ontology), pid: 'pid:pid', sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'Sample Name', sample_attribute_type: Factory(:string_sample_attribute_type),is_title: true, required: true, isa_tag_id: IsaTag.find_by_title("sample").id, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'sample characteristic 1', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, isa_tag_id: IsaTag.find_by_title("sample_characteristic").id, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'sample characteristic 2', sample_attribute_type: Factory(:controlled_vocab_attribute_type), isa_tag_id: IsaTag.find_by_title("sample_characteristic").id, sample_controlled_vocab: Factory(:apples_sample_controlled_vocab), sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'sample characteristic 3', sample_attribute_type: Factory(:controlled_vocab_attribute_type, title: 'Ontology'), isa_tag_id: IsaTag.find_by_title("sample_characteristic").id, sample_controlled_vocab: Factory(:obi_ontology), pid: 'pid:pid', sample_type: type)
  end
end

Factory.define(:isa_assay_sample_type, parent: :sample_type) do |f|
  f.ignore do
    linked_sample_type nil
  end
  f.sequence(:title) { |n| "ISA Assay #{n}" }
  f.after_build do |type, eval|
    type.sample_attributes << Factory.build(:sample_attribute, title: 'Input', sample_attribute_type: Factory(:sample_multi_sample_attribute_type), linked_sample_type: eval.linked_sample_type, required: true, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'Protocol Assay 1', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, isa_tag_id: IsaTag.find_by_title("protocol").id, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'Assay 1 parameter value 1', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, isa_tag_id: IsaTag.find_by_title("parameter_value").id, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'Assay 1 parameter value 2', sample_attribute_type: Factory(:controlled_vocab_attribute_type), isa_tag_id: IsaTag.find_by_title("parameter_value").id, sample_controlled_vocab: Factory(:apples_sample_controlled_vocab), sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'Assay 1 parameter value 3', sample_attribute_type: Factory(:controlled_vocab_attribute_type, title: 'Ontology'), isa_tag_id: IsaTag.find_by_title("parameter_value").id, sample_controlled_vocab: Factory(:obi_ontology), pid: 'pid:pid', sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'Extract Name', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, is_title: true, isa_tag_id: IsaTag.find_by_title("other_material").id, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'other material characteristic 1', sample_attribute_type: Factory(:string_sample_attribute_type), required: true, isa_tag_id: IsaTag.find_by_title("other_material_characteristic").id, sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'other material characteristic 2', sample_attribute_type: Factory(:controlled_vocab_attribute_type), isa_tag_id: IsaTag.find_by_title("other_material_characteristic").id, sample_controlled_vocab: Factory(:apples_sample_controlled_vocab), sample_type: type)
    type.sample_attributes << Factory.build(:sample_attribute, title: 'other material characteristic 3', sample_attribute_type: Factory(:controlled_vocab_attribute_type, title: 'Ontology'), isa_tag_id: IsaTag.find_by_title("other_material_characteristic").id, sample_controlled_vocab: Factory(:efo_ontology), pid: 'pid:pid', sample_type: type)
  end
end
