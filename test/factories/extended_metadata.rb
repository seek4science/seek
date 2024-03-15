FactoryBot.define do

  factory(:simple_extended_metadata, class: ExtendedMetadata) do
    association :extended_metadata_type, factory: :simple_study_extended_metadata_type, strategy: :create
    after(:build) do |em|
      em.set_attribute_value(:name, 'Fred Bloggs')
      em.set_attribute_value(:age, 44)
      em.set_attribute_value(:date, '2024-01-01')
    end
  end

end