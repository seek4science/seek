FactoryBot.define do
  # Placeholder
  factory(:placeholder) do
    with_project_contributor
    sequence(:title) { |n| "A Placeholder #{n}" }
  end
  
  factory(:public_placeholder, parent: :placeholder) do
    policy { FactoryBot.create(:downloadable_public_policy) }
  end
  
  factory(:private_placeholder, parent: :placeholder) do
    policy { FactoryBot.create(:private_policy) }
  end
  
  factory(:min_placeholder, class: Placeholder) do
    with_project_contributor
    title { 'A Minimal Placeholder' }
    policy { FactoryBot.create(:downloadable_public_policy) }
  end
  
  factory(:max_placeholder, class: Placeholder) do
    with_project_contributor
    title { 'A Maximal Placeholder' }
    description { 'The Maximal Placeholder' }
    policy { FactoryBot.create(:downloadable_public_policy) }
    assays { [FactoryBot.create(:public_assay)] }
    other_creators { 'Blogs, Joe' }
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: FactoryBot.create(:person, first_name: 'Some', last_name: 'One'))] }
  end
end
