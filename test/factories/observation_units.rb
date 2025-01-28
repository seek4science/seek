FactoryBot.define do
  factory(:observation_unit) do
    title { 'Observation Unit' }
    description { 'very simple obs unit'}
    association :contributor, factory: :person, strategy: :create
    after(:build) do |a|
      a.study ||= FactoryBot.create(:study, contributor: a.contributor)
    end
  end

  factory(:min_observation_unit, parent: :observation_unit) do
    title { 'A Minimal Observation Unit' }
    policy { FactoryBot.create(:public_policy) }
    association :study, factory: :study, strategy: :create
    description { nil }
  end

  factory(:max_observation_unit, class: ObservationUnit) do
    title { 'Max observation unit'}
    description { 'the maximum one'}
    policy { FactoryBot.create(:public_policy) }
    other_creators { 'Blogs, Joe' }
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: FactoryBot.create(:person, first_name: 'Some', last_name: 'One'))] }
    association :contributor, factory: :person, strategy: :create
    association :extended_metadata, factory: :simple_observation_unit_extended_metadata, strategy: :create
    after(:build) do |a|
      a.study ||= FactoryBot.create(:study, contributor: a.contributor)
    end
    samples { build_list :sample, 3}
    data_files { build_list :data_file, 3}
  end

end