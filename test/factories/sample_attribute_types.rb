# SampleAttributeType
Factory.define(:integer_sample_attribute_type, class: SampleAttributeType) do |f|
  f.sequence(:title) { |n| "Integer attribute type #{n}" }
  f.base_type Seek::Samples::BaseType::INTEGER
end

Factory.define(:string_sample_attribute_type, class: SampleAttributeType) do |f|
  f.sequence(:title) { |n| "String attribute type #{n}" }
  f.base_type Seek::Samples::BaseType::STRING
end

Factory.define(:xxx_string_sample_attribute_type, parent: :string_sample_attribute_type) do |f|
  f.regexp '.*xxx.*'
end

Factory.define(:float_sample_attribute_type, class: SampleAttributeType) do |f|
  f.sequence(:title) { |n| "Float attribute type #{n}" }
  f.base_type Seek::Samples::BaseType::FLOAT
end

Factory.define(:datetime_sample_attribute_type, class: SampleAttributeType) do |f|
  f.sequence(:title) { |n| "DateTime attribute type #{n}" }
  f.base_type Seek::Samples::BaseType::DATE_TIME
end

Factory.define(:text_sample_attribute_type, class: SampleAttributeType) do |f|
  f.sequence(:title) { |n| "Text attribute type #{n}" }
  f.base_type Seek::Samples::BaseType::TEXT
end

Factory.define(:boolean_sample_attribute_type, class: SampleAttributeType) do |f|
  f.sequence(:title) { |n| "Boolean attribute type #{n}" }
  f.base_type Seek::Samples::BaseType::BOOLEAN
end

Factory.define(:strain_sample_attribute_type, class: SampleAttributeType) do |f|
  f.sequence(:title) { |n| "Strain attribute type #{n}" }
  f.base_type Seek::Samples::BaseType::SEEK_STRAIN
end

Factory.define(:sample_sample_attribute_type, class: SampleAttributeType) do |f|
  f.sequence(:title) { |n| "Sample attribute type #{n}" }
  f.base_type Seek::Samples::BaseType::SEEK_SAMPLE
end

Factory.define(:sample_multi_sample_attribute_type, class: SampleAttributeType) do |f|
  f.sequence(:title) { |n| "Sample multi attribute type #{n}" }
  f.base_type Seek::Samples::BaseType::SEEK_SAMPLE_MULTI
end

Factory.define(:custom_metadata_sample_attribute_type, class: SampleAttributeType) do |f|
  f.sequence(:title) { |n| "Linked Custom Metadata attribute type #{n}" }
  f.base_type Seek::Samples::BaseType::LINKED_CUSTOM_METADATA
end

Factory.define(:data_file_sample_attribute_type, class: SampleAttributeType) do |f|
  f.sequence(:title) { |n| "Data file attribute type #{n}" }
  f.base_type Seek::Samples::BaseType::SEEK_DATA_FILE
end

# very simple persons name, must be 2 words, first and second word starting with capital with all letters
Factory.define(:full_name_sample_attribute_type, parent: :string_sample_attribute_type) do |f|
  f.regexp '[A-Z][a-z]+[ ][A-Z][a-z]+'
  f.title 'Full name'
end

#NCBI ID
Factory.define(:ncbi_id_sample_attribute_type, parent: :string_sample_attribute_type) do |f|
  f.title 'NCBI ID'
  f.regexp '[0-9]+'
end

# positive integer
Factory.define(:age_sample_attribute_type, parent: :integer_sample_attribute_type) do |f|
  f.regexp '^[1-9]\d*$'
  f.title 'Age'
end

# positive float
Factory.define(:weight_sample_attribute_type, parent: :float_sample_attribute_type) do |f|
  f.regexp '^[1-9]\d*[.][1-9]\d*$'
  f.title 'Weight'
end

# uk postcode - taken from http://regexlib.com/REDetails.aspx?regexp_id=260
Factory.define(:postcode_sample_attribute_type, parent: :string_sample_attribute_type) do |f|
  f.regexp '^([A-PR-UWYZ0-9][A-HK-Y0-9][AEHMNPRTVXY0-9]?[ABEHMNPRVWXY0-9]? {1,2}[0-9][ABD-HJLN-UW-Z]{2}|GIR 0AA)$'
  f.title 'Post Code'
end

Factory.define(:address_sample_attribute_type, parent: :text_sample_attribute_type) do |f|
  f.title 'Address'
end

Factory.define(:controlled_vocab_attribute_type, class: SampleAttributeType) do |f|
  f.sequence(:title) { |n| "CV attribute type #{n}" }
  f.base_type 'CV'
end

Factory.define(:cv_list_attribute_type, class: SampleAttributeType) do |f|
  f.sequence(:title) { |n| "CV List attribute type #{n}" }
  f.base_type 'CVList'
end

# SampleControlledVocabTerm
Factory.define(:sample_controlled_vocab_term) do |_f|
end

# SampleControlledVocab
Factory.define(:apples_sample_controlled_vocab, class: SampleControlledVocab) do |f|
  f.sequence(:title) { |n| "apples controlled vocab #{n}" }
  f.after_build do |vocab|
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'Granny Smith')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'Golden Delicious')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'Bramley')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: "Cox's Orange Pippin")
  end
end

Factory.define(:sample_controlled_vocab, class: SampleControlledVocab) do |f|
  f.sequence(:title) { |n| "sample controlled vocab #{n}" }
end

Factory.define(:ontology_sample_controlled_vocab, parent: :sample_controlled_vocab) do |f|
  f.source_ontology 'http://ontology.org'
  f.ols_root_term_uri 'http://ontology.org/#parent'
  f.after_build do |vocab|
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'Parent',iri:'http://ontology.org/#parent',parent_iri:'')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'Mother',iri:'http://ontology.org/#mother',parent_iri:'http://ontology.org/#parent')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'Father',iri:'http://ontology.org/#father',parent_iri:'http://ontology.org/#parent')
  end
end

Factory.define(:topics_controlled_vocab, parent: :sample_controlled_vocab) do |f|
  f.title 'Topics'
  f.ols_root_term_uri 'http://edamontology.org/topic_0003'
  f.key SampleControlledVocab::SystemVocabs.database_key_for_property(:topics)
  f.source_ontology 'edam'
  f.after_build do |vocab|
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'Topic',iri:'http://edamontology.org/topic_0003',parent_iri:'')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'Biomedical science',iri:'http://edamontology.org/topic_3344',parent_iri:'http://edamontology.org/topic_0003')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'Chemistry',iri:'http://edamontology.org/topic_3314',parent_iri:'http://edamontology.org/topic_0003')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'Sample collections',iri:'http://edamontology.org/topic_3277',parent_iri:'http://edamontology.org/topic_3344')
  end
end

Factory.define(:operations_controlled_vocab, parent: :sample_controlled_vocab) do |f|
  f.title 'Operations'
  f.ols_root_term_uri 'http://edamontology.org/operation_0004'
  f.key SampleControlledVocab::SystemVocabs.database_key_for_property(:operations)
  f.source_ontology 'edam'
  f.after_build do |vocab|
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'Operation',iri:'http://edamontology.org/operation_0004',parent_iri:'')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'Correlation',iri:'http://edamontology.org/operation_3465',parent_iri:'http://edamontology.org/operation_0004')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'Clustering',iri:'http://edamontology.org/operation_3432',parent_iri:'http://edamontology.org/operation_0004')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'Expression correlation analysis',iri:'http://edamontology.org/operation_3463',parent_iri:'http://edamontology.org/operation_3465')
  end
end

Factory.define(:data_types_controlled_vocab, parent: :sample_controlled_vocab) do |f|
  f.title 'Data'
  f.ols_root_term_uri 'http://edamontology.org/data_0006'
  f.key SampleControlledVocab::SystemVocabs.database_key_for_property(:data_types)
  f.source_ontology 'edam'
  f.after_build do |vocab|
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'Data',iri:'http://edamontology.org/data_0006',parent_iri:'')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'Sequence features metadata',iri: 'http://edamontology.org/data_2914', parent_iri:'http://edamontology.org/data_0006')
  end
end

Factory.define(:data_formats_controlled_vocab, parent: :sample_controlled_vocab) do |f|
  f.title 'Formats'
  f.ols_root_term_uri 'http://edamontology.org/format_1915'
  f.key SampleControlledVocab::SystemVocabs.database_key_for_property(:data_formats)
  f.source_ontology 'edam'
  f.after_build do |vocab|
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'Format',iri:'http://edamontology.org/format_1915',parent_iri:'')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'JSON',iri: 'http://edamontology.org/format_3464', parent_iri:'http://edamontology.org/format_1915')
  end
end

Factory.define(:efo_ontology, class: SampleControlledVocab) do |f|
  f.sequence(:title) { |n| "EFO ontology #{n}" }
  f.source_ontology 'EFO'
  f.ols_root_term_uri 'http://www.ebi.ac.uk/efo/EFO_0000635'
  f.after_build do |vocab|
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'anatomical entity')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'retroperitoneal space')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'abdominal cavity')
  end
end

Factory.define(:obi_ontology, class: SampleControlledVocab) do |f|
  f.sequence(:title) { |n| "OBI ontology #{n}" }
  f.source_ontology 'OBI'
  f.ols_root_term_uri 'http://purl.obolibrary.org/obo/OBI_0000094'
  f.after_build do |vocab|
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'dissection')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'enzymatic cleavage')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'non specific enzymatic cleavage')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'protease cleavage')
    vocab.sample_controlled_vocab_terms << Factory.build(:sample_controlled_vocab_term, label: 'DNA restriction enzyme digestion')
  end
end