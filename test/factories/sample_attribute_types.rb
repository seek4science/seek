FactoryBot.define do
  # SampleAttributeType
  factory(:integer_sample_attribute_type, class: SampleAttributeType) do
    sequence(:title) { |n| "Integer attribute type #{n}" }
    base_type { Seek::Samples::BaseType::INTEGER }
  end
  
  factory(:string_sample_attribute_type, class: SampleAttributeType) do
    sequence(:title) { |n| "String attribute type #{n}" }
    base_type { Seek::Samples::BaseType::STRING }
  end
  
  factory(:xxx_string_sample_attribute_type, parent: :string_sample_attribute_type) do
    regexp { '.*xxx.*' }
  end
  
  factory(:float_sample_attribute_type, class: SampleAttributeType) do
    sequence(:title) { |n| "Float attribute type #{n}" }
    base_type { Seek::Samples::BaseType::FLOAT }
  end
  
  factory(:datetime_sample_attribute_type, class: SampleAttributeType) do
    sequence(:title) { |n| "DateTime attribute type #{n}" }
    base_type { Seek::Samples::BaseType::DATE_TIME }
  end
  
  factory(:text_sample_attribute_type, class: SampleAttributeType) do
    sequence(:title) { |n| "Text attribute type #{n}" }
    base_type { Seek::Samples::BaseType::TEXT }
  end
  
  factory(:boolean_sample_attribute_type, class: SampleAttributeType) do
    sequence(:title) { |n| "Boolean attribute type #{n}" }
    base_type { Seek::Samples::BaseType::BOOLEAN }
  end
  
  factory(:strain_sample_attribute_type, class: SampleAttributeType) do
    sequence(:title) { |n| "Strain attribute type #{n}" }
    base_type { Seek::Samples::BaseType::SEEK_STRAIN }
  end
  
  factory(:sample_sample_attribute_type, class: SampleAttributeType) do
    sequence(:title) { |n| "Sample attribute type #{n}" }
    base_type { Seek::Samples::BaseType::SEEK_SAMPLE }
  end
  
  factory(:sample_multi_sample_attribute_type, class: SampleAttributeType) do
    sequence(:title) { |n| "Sample multi attribute type #{n}" }
    base_type { Seek::Samples::BaseType::SEEK_SAMPLE_MULTI }
  end

  factory(:custom_metadata_sample_attribute_type, class: SampleAttributeType) do
    sequence(:title) { |n| "Linked Custom Metadata attribute type #{n}" }
    base_type { Seek::Samples::BaseType::LINKED_CUSTOM_METADATA }
  end

  factory(:custom_metadata_multi_sample_attribute_type, class: SampleAttributeType) do
    sequence(:title) { |n| "Linked Custom Metadata multi attribute type #{n}" }
    base_type { Seek::Samples::BaseType::LINKED_CUSTOM_METADATA_MULTI }
  end
  
  factory(:data_file_sample_attribute_type, class: SampleAttributeType) do
    sequence(:title) { |n| "Data file attribute type #{n}" }
    base_type { Seek::Samples::BaseType::SEEK_DATA_FILE }
  end
  
  # very simple persons name, must be 2 words, first and second word starting with capital with all letters
  factory(:full_name_sample_attribute_type, parent: :string_sample_attribute_type) do
    regexp { '[A-Z][a-z]+[ ][A-Z][a-z]+' }
    title { 'Full name' }
  end
  
  #NCBI ID
  factory(:ncbi_id_sample_attribute_type, parent: :string_sample_attribute_type) do
    title { 'NCBI ID' }
    regexp { '[0-9]+' }
  end
  
  # positive integer
  factory(:age_sample_attribute_type, parent: :integer_sample_attribute_type) do
    regexp { '^[1-9]\d*$' }
    title { 'Age' }
  end
  
  # positive float
  factory(:weight_sample_attribute_type, parent: :float_sample_attribute_type) do
    regexp { '^[1-9]\d*[.][1-9]\d*$' }
    title { 'Weight' }
  end
  
  # uk postcode - taken from http://regexlib.com/REDetails.aspx?regexp_id=260
  factory(:postcode_sample_attribute_type, parent: :string_sample_attribute_type) do
    regexp { '^([A-PR-UWYZ0-9][A-HK-Y0-9][AEHMNPRTVXY0-9]?[ABEHMNPRVWXY0-9]? {1,2}[0-9][ABD-HJLN-UW-Z]{2}|GIR 0AA)$' }
    title { 'Post Code' }
  end
  
  factory(:address_sample_attribute_type, parent: :text_sample_attribute_type) do
    title { 'Address' }
  end
  
  factory(:controlled_vocab_attribute_type, class: SampleAttributeType) do
    sequence(:title) { |n| "CV attribute type #{n}" }
    base_type { 'CV' }
  end
  
  factory(:cv_list_attribute_type, class: SampleAttributeType) do
    sequence(:title) { |n| "CV List attribute type #{n}" }
    base_type { 'CVList' }
  end
  
  # SampleControlledVocabTerm
  factory(:sample_controlled_vocab_term) do |_f|
  end
  
  # SampleControlledVocab
  factory(:apples_sample_controlled_vocab, class: SampleControlledVocab) do
    sequence(:title) { |n| "apples controlled vocab #{n}" }
    after(:build) do |vocab|
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'Granny Smith')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'Golden Delicious')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'Bramley')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: "Cox's Orange Pippin")
    end
  end
  
  factory(:sample_controlled_vocab, class: SampleControlledVocab) do
    sequence(:title) { |n| "sample controlled vocab #{n}" }
  end
  
  factory(:ontology_sample_controlled_vocab, parent: :sample_controlled_vocab) do
    source_ontology { 'http://ontology.org' }
    ols_root_term_uri { 'http://ontology.org/#parent' }
    after(:build) do |vocab|
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'Parent',iri:'http://ontology.org/#parent',parent_iri:'')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'Mother',iri:'http://ontology.org/#mother',parent_iri:'http://ontology.org/#parent')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'Father',iri:'http://ontology.org/#father',parent_iri:'http://ontology.org/#parent')
    end
  end
  
  factory(:topics_controlled_vocab, parent: :sample_controlled_vocab) do
    title { 'Topics' }
    ols_root_term_uri { 'http://edamontology.org/topic_0003' }
    key { SampleControlledVocab::SystemVocabs.database_key_for_property(:topics) }
    source_ontology { 'edam' }
    after(:build) do |vocab|
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'Topic',iri:'http://edamontology.org/topic_0003',parent_iri:'')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'Biomedical science',iri:'http://edamontology.org/topic_3344',parent_iri:'http://edamontology.org/topic_0003')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'Chemistry',iri:'http://edamontology.org/topic_3314',parent_iri:'http://edamontology.org/topic_0003')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'Sample collections',iri:'http://edamontology.org/topic_3277',parent_iri:'http://edamontology.org/topic_3344')
    end
  end
  
  factory(:operations_controlled_vocab, parent: :sample_controlled_vocab) do
    title { 'Operations' }
    ols_root_term_uri { 'http://edamontology.org/operation_0004' }
    key { SampleControlledVocab::SystemVocabs.database_key_for_property(:operations) }
    source_ontology { 'edam' }
    after(:build) do |vocab|
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'Operation',iri:'http://edamontology.org/operation_0004',parent_iri:'')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'Correlation',iri:'http://edamontology.org/operation_3465',parent_iri:'http://edamontology.org/operation_0004')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'Clustering',iri:'http://edamontology.org/operation_3432',parent_iri:'http://edamontology.org/operation_0004')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'Expression correlation analysis',iri:'http://edamontology.org/operation_3463',parent_iri:'http://edamontology.org/operation_3465')
    end
  end
  
  factory(:data_types_controlled_vocab, parent: :sample_controlled_vocab) do
    title { 'Data' }
    ols_root_term_uri { 'http://edamontology.org/data_0006' }
    key { SampleControlledVocab::SystemVocabs.database_key_for_property(:data_types) }
    source_ontology { 'edam' }
    after(:build) do |vocab|
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'Data',iri:'http://edamontology.org/data_0006',parent_iri:'')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'Sequence features metadata',iri: 'http://edamontology.org/data_2914', parent_iri:'http://edamontology.org/data_0006')
    end
  end
  
  factory(:data_formats_controlled_vocab, parent: :sample_controlled_vocab) do
    title { 'Formats' }
    ols_root_term_uri { 'http://edamontology.org/format_1915' }
    key { SampleControlledVocab::SystemVocabs.database_key_for_property(:data_formats) }
    source_ontology { 'edam' }
    after(:build) do |vocab|
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'Format',iri:'http://edamontology.org/format_1915',parent_iri:'')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'JSON',iri: 'http://edamontology.org/format_3464', parent_iri:'http://edamontology.org/format_1915')
    end
  end
  
  factory(:efo_ontology, class: SampleControlledVocab) do
    sequence(:title) { |n| "EFO ontology #{n}" }
    source_ontology { 'EFO' }
    ols_root_term_uri { 'http://www.ebi.ac.uk/efo/EFO_0000635' }
    after(:build) do |vocab|
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'anatomical entity')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'retroperitoneal space')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'abdominal cavity')
    end
  end
  
  factory(:obi_ontology, class: SampleControlledVocab) do
    sequence(:title) { |n| "OBI ontology #{n}" }
    source_ontology { 'OBI' }
    ols_root_term_uri { 'http://purl.obolibrary.org/obo/OBI_0000094' }
    after(:build) do |vocab|
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'dissection')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'enzymatic cleavage')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'non specific enzymatic cleavage')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'protease cleavage')
      vocab.sample_controlled_vocab_terms << FactoryBot.build(:sample_controlled_vocab_term, label: 'DNA restriction enzyme digestion')
    end
  end

end
