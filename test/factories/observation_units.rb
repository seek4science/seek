FactoryBot.define do
  factory(:observation_unit) do
    title { 'Observation Unit' }
    description { 'very simple obs unit'}
    with_project_contributor
  end

  factory(:max_observation_unit, class: ObservationUnit) do
    title { 'Max observation unit'}
    description { 'the maximum one'}
    with_project_contributor
    other_creators { 'Blogs, Joe' }
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: FactoryBot.create(:person, first_name: 'Some', last_name: 'One'))] }
    association :extended_metadata, factory: :simple_observation_unit_extended_metadata, strategy: :create
    association :study, factory: :study, strategy: :create
  end

end