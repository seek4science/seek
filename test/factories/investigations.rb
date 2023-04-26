FactoryBot.define do
  # Investigation
  factory(:investigation, class: Investigation) do
    with_project_contributor
    sequence(:title) { |n| "Investigation#{n}" }
  end
  
  factory(:public_investigation, parent: :investigation) do
    policy { Factory(:public_policy) }
  end
  
  factory(:investigation_with_study_and_assay, parent: :investigation) do
    studies { [Factory(:study_with_assay)] }
  end
  
  factory(:min_investigation, class: Investigation) do
    with_project_contributor
    title "A Minimal Investigation"
  end
  
  factory(:max_investigation, parent: :min_investigation) do
    with_project_contributor
    title "A Maximal Investigation"
    other_creators "Max Blumenthal, Ed Snowden"
    description "Investigation of the Human Genome"
    discussion_links { [Factory.build(:discussion_link, label:'Slack')] }
    after_build do |i|
      i.studies = [Factory(:max_study, contributor: i.contributor, policy: Factory(:public_policy))]
    end
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: Factory(:person, first_name: 'Some', last_name: 'One'))] }
  end
end
