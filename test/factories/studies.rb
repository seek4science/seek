FactoryBot.define do
  # Study
  factory(:study) do
    sequence(:title) { |n| "Study#{n}" }
    association :contributor, factory: :person
    after_build do |s|
      s.investigation ||= Factory(:investigation, contributor: s.contributor, policy: s.policy.try(:deep_copy))
    end
  end
  
  factory(:public_study, parent: :study) do
    policy { Factory(:public_policy) }
    investigation { Factory(:public_investigation) }
  end
  
  factory(:study_with_assay, parent: :study) do
    assays { [Factory(:assay)] }
  end
  
  factory(:min_study, class: Study) do
    title { "A Minimal Study" }
    association :contributor, factory: :person
    after_build do |s|
      s.investigation ||= Factory(:min_investigation, contributor: s.contributor, policy: s.policy.try(:deep_copy))
    end
  end
  
  factory(:max_study, parent: :min_study) do
    title { "A Maximal Study" }
    description { "The Study of many things" }
    discussion_links { [Factory.build(:discussion_link, label:'Slack')] }
    experimentalists { "Wet lab people" }
    other_creators { "Marie Curie" }
    after_build do |s|
      s.assays = [Factory(:max_assay, contributor: s.contributor, policy: Factory(:public_policy))]
    end
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: Factory(:person, first_name: 'Some', last_name: 'One'))] }
  end
end
