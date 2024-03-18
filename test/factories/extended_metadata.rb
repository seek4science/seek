FactoryBot.define do

  factory(:simple_extended_metadata, class: ExtendedMetadata) do
    association :extended_metadata_type, factory: :simple_study_extended_metadata_type, strategy: :create
    after(:build) do |em|
      em.set_attribute_value(:name, 'Fred Bloggs')
      em.set_attribute_value(:age, 44)
      em.set_attribute_value(:date, '2024-01-01')
    end
  end

  factory(:family_extended_metadata, class: ExtendedMetadata) do
    association :extended_metadata_type, factory: :family_extended_metadata_type, strategy: :create
    after(:build) do |em|
      em.set_attribute_value(:dad, {"first_name":"john", "last_name":"liddell"})
      em.set_attribute_value(:mom, {"first_name":"lily", "last_name":"liddell"})
      em.set_attribute_value(:child, {"0":{"first_name":"rabbit", "last_name":"wonderland"},"1":{"first_name":"mad", "last_name":"hatter"}})
    end
  end

  factory(:role_multiple_extended_metadata, class: ExtendedMetadata) do
    association :extended_metadata_type, factory: :role_multiple_extended_metadata_type, strategy: :create
    after(:build) do |em|
      em.set_attribute_value(:role_email, "alice@email.com")
      em.set_attribute_value(:role_phone, "0012345")
      em.set_attribute_value(:role_name, {"first_name":"alice", "last_name": "liddell"})
      em.set_attribute_value(:role_address, {"street":"wonder","city": "land" })
    end
  end

end