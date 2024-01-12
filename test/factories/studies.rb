FactoryBot.define do
  # Study
  factory(:study) do
    sequence(:title) { |n| "Study#{n}" }
    association :contributor, factory: :person, strategy: :create
    after(:build) do |s|
      s.investigation ||= FactoryBot.create(:investigation, contributor: s.contributor, policy: s.policy.try(:deep_copy))
    end
  end

  factory(:public_study, parent: :study) do
    policy { FactoryBot.create(:public_policy) }
    investigation { FactoryBot.create(:public_investigation) }
  end

  factory(:study_with_assay, parent: :study) do
    assays { [FactoryBot.create(:assay)] }
  end

  factory(:min_study, class: Study) do
    title { "A Minimal Study" }
    association :contributor, factory: :person, strategy: :create
    after(:build) do |s|
      s.investigation ||= FactoryBot.create(:min_investigation, contributor: s.contributor, policy: s.policy.try(:deep_copy))
    end
  end

  factory(:max_study, parent: :min_study) do
    title { "A Maximal Study" }
    description { "The Study of many things" }
    discussion_links { [FactoryBot.build(:discussion_link, label:'Slack')] }
    experimentalists { "Wet lab people" }
    other_creators { "Marie Curie" }
    after(:build) do |s|
      s.assays = [FactoryBot.create(:max_assay, contributor: s.contributor, policy: FactoryBot.create(:public_policy))]
    end
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: FactoryBot.create(:person, first_name: 'Some', last_name: 'One'))] }
  end

  factory(:isa_json_compliant_study, parent: :study) do
    title { 'ISA JSON compliant study' }
    description { 'A study which is linked to an ISA JSON compliant investigation and has two sample types linked to it.' }
    after(:build) do |study|
      study.investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true)
      source_st = FactoryBot.create(:isa_source_sample_type)
      sample_collection_st = FactoryBot.create(:isa_sample_collection_sample_type, linked_sample_type: source_st)
      study.sample_types = [source_st, sample_collection_st]
    end
  end
end
