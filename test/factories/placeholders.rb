FactoryBot.define do
  # Placeholder
  factory(:placeholder) do
    with_project_contributor
    sequence(:title) { |n| "A Placeholder #{n}" }

    after(:build) do |placeholder|
      placeholder.projects = [placeholder.contributor.projects.first] if placeholder.projects.empty?
    end
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
    file_template { FactoryBot.create(:public_file_template) }
    data_file { FactoryBot.create(:public_data_file) }

    after(:create) do |placeholder|
      placeholder.annotate_with(['Placeholder-tag1', 'Placeholder-tag2', 'Placeholder-tag3', 'Placeholder-tag4', 'Placeholder-tag5'], 'tag', placeholder.contributor)
      placeholder.save!
    end
  end
end
