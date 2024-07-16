FactoryBot.define do
  # Sample
  factory(:sample) do
    sequence(:title) { |n| "Sample #{n}" }
    association :sample_type, factory: :simple_sample_type, strategy: :create
    with_project_contributor

    after(:build) do |sample|
      sample.set_attribute_value(:the_title, sample.title) if sample.data.key?(:the_title)
    end
  end

  factory(:patient_sample, parent: :sample) do
    association :sample_type, factory: :patient_sample_type, strategy: :create
    after(:build) do |sample|
      sample.set_attribute_value('full name', 'Fred Bloggs')
      sample.set_attribute_value(:age, 44)
      sample.set_attribute_value(:weight, 88.7)
    end
  end

  factory(:sample_from_file, parent: :sample) do
    sequence(:title) { |n| "Sample #{n}" }
    association :sample_type, factory: :strain_sample_type, strategy: :create

    after(:build) do |sample|
      sample.set_attribute_value(:name, sample.title) if sample.data.key?(:name)
      sample.set_attribute_value(:seekstrain, '1234')
    end

    after(:build) do |sample|
      sample.originating_data_file = FactoryBot.create(:strain_sample_data_file, projects:sample.projects, contributor:sample.contributor) if sample.originating_data_file.nil?
    end
  end

  factory(:min_sample, parent: :sample) do
    association :sample_type, factory: :min_sample_type, strategy: :create
    association :contributor, factory: :person, strategy: :create
    after(:build) do |sample|
      sample.set_attribute_value(:full_name, 'Fred Bloggs')
    end
  end

  factory(:max_sample, parent: :sample) do
    association :sample_type, factory: :max_sample_type, strategy: :create
    association :contributor, factory: :person, strategy: :create
    after(:build) do |sample|
      sample.annotate_with(['tag1', 'tag2'], 'tag', sample.contributor)
      sample.set_attribute_value(:full_name, 'Fred Bloggs')
      sample.set_attribute_value(:address, "HD")
      sample.set_attribute_value(:postcode, "M13 9PL")
      sample.set_attribute_value('CAPITAL key', 'key must remain capitalised')
      sample.set_attribute_value(:apple,['Bramley'])
      sample.set_attribute_value(:apples, ['Granny Smith','Golden Delicious'])
      sample.set_attribute_value(:patients, [FactoryBot.create(:patient_sample).id.to_s, FactoryBot.create(:patient_sample).id.to_s])
      sample.set_attribute_value(:weight, '3.7')
      sample.set_attribute_value(:age, '42')
      sample.set_attribute_value(:bool, true)
    end
  end

  factory(:isa_source, parent: :sample) do
    sequence(:title) { |n| "Source sample #{n}" }
    association :sample_type, factory: :isa_source_sample_type, strategy: :create
    after(:build) do |sample|
      sample.set_attribute_value('Source Name', sample.title)
      sample.set_attribute_value('Source Characteristic 1', 'Source Characteristic 1')
      sample.set_attribute_value('Source Characteristic 2', sample.sample_type.sample_attributes.find_by_title('Source Characteristic 2').sample_controlled_vocab.sample_controlled_vocab_terms.first.label)
      sample.set_attribute_value('Source Characteristic 3', sample.sample_type.sample_attributes.find_by_title('Source Characteristic 3').sample_controlled_vocab.sample_controlled_vocab_terms.first.label)
    end
  end

  factory(:isa_sample, parent: :sample) do
    transient do
      linked_samples { nil }
    end
    sequence(:title) { |n| "Source #{n}" }
    association :sample_type, factory: :isa_sample_collection_sample_type, strategy: :create
    after(:build) do |sample, eval|
      sample.data = {
        Input: eval.linked_samples.map(&:id),
      }
      sample.set_attribute_value('Sample Name', sample.title)
      sample.set_attribute_value('sample collection', 'sample collection')
      sample.set_attribute_value('sample collection parameter value 1', 'sample collection parameter value 1')
      sample.set_attribute_value('sample collection parameter value 2', sample.sample_type.sample_attributes.find_by_title('sample collection parameter value 2').sample_controlled_vocab.sample_controlled_vocab_terms.first.label)
      sample.set_attribute_value('sample characteristic 1', 'sample characteristic 1')
      sample.set_attribute_value('sample characteristic 2', sample.sample_type.sample_attributes.find_by_title('sample characteristic 2').sample_controlled_vocab.sample_controlled_vocab_terms.first.label)
    end
  end

  factory(:isa_material_assay_sample, parent: :sample) do
    transient do
      linked_samples { nil }
    end
    sequence(:title) { |n| "Material output #{n}" }
    association :sample_type, factory: :isa_assay_material_sample_type, strategy: :create
    after(:build) do |sample, eval|
      sample.data = {
        Input: eval.linked_samples.map(&:id),
      }
      sample.set_attribute_value('Extract Name', sample.title)
      sample.set_attribute_value('Protocol Assay 1', 'Protocol Assay 1')
      sample.set_attribute_value('Assay 1 parameter value 1', 'Assay 1 parameter value 1')
      sample.set_attribute_value('Assay 1 parameter value 2', sample.sample_type.sample_attributes.find_by_title('Assay 1 parameter value 2').sample_controlled_vocab.sample_controlled_vocab_terms.first.label)
      sample.set_attribute_value('other material characteristic 1', 'other material characteristic 1')
      sample.set_attribute_value('other material characteristic 2', sample.sample_type.sample_attributes.find_by_title('other material characteristic 2').sample_controlled_vocab.sample_controlled_vocab_terms.first.label)
    end
  end

  factory(:isa_datafile_assay_sample, parent: :sample) do
    transient do
      linked_samples { nil }
    end
    sequence(:title) { |n| "Data file #{n}" }
    association :sample_type, factory: :isa_assay_data_file_sample_type, strategy: :create
    after(:build) do |sample, eval|
      sample.data = {
        Input: eval.linked_samples.map(&:id),
      }
      sample.set_attribute_value('File Name', sample.title)
      sample.set_attribute_value('Protocol Assay 2', 'Protocol Assay 2')
      sample.set_attribute_value('Assay 2 parameter value 1', 'Assay 2 parameter value 1')
      sample.set_attribute_value('Assay 2 parameter value 2', sample.sample_type.sample_attributes.find_by_title('Assay 2 parameter value 2').sample_controlled_vocab.sample_controlled_vocab_terms.first.label)
      sample.set_attribute_value('sample characteristic 1', 'sample characteristic 1')
      sample.set_attribute_value('sample characteristic 2', sample.sample_type.sample_attributes.find_by_title('sample characteristic 2').sample_controlled_vocab.sample_controlled_vocab_terms.first.label)
    end
  end
end
