FactoryBot.define do
  # Investigation
  factory(:investigation, class: Investigation) do
    with_project_contributor
    sequence(:title) { |n| "Investigation#{n}" }
  end
  
  factory(:public_investigation, parent: :investigation) do
    policy { FactoryBot.create(:public_policy) }
  end
  
  factory(:investigation_with_study_and_assay, parent: :investigation) do
    studies { [FactoryBot.create(:study_with_assay)] }
  end
  
  factory(:min_investigation, class: Investigation) do
    with_project_contributor
    title { "A Minimal Investigation" }
  end
  
  factory(:max_investigation, parent: :min_investigation) do
    with_project_contributor
    title { "A Maximal Investigation" }
    other_creators { "Max Blumenthal, Ed Snowden" }
    description { "Investigation of the Human Genome" }
    discussion_links { [FactoryBot.build(:discussion_link, label:'Slack')] }
    after(:build) do |i|
      i.studies = [FactoryBot.create(:max_study, contributor: i.contributor, policy: FactoryBot.create(:public_policy))]
    end
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: FactoryBot.create(:person, first_name: 'Some', last_name: 'One'))] }
  end
end
