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
    end
  end
end
