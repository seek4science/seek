# Study
Factory.define(:study) do |f|
  f.sequence(:title) { |n| "Study#{n}" }
  f.association :contributor, factory: :person
  f.after_build do |s|
    s.investigation ||= Factory(:investigation, contributor: s.contributor, policy: s.policy.try(:deep_copy))
  end
end

Factory.define(:study_with_assay, parent: :study) do |f|
  f.assays { [Factory(:assay)] }
end

Factory.define(:min_study, class: Study) do |f|
  f.title "A Minimal Study"
  f.association :contributor, factory: :person
  f.after_build do |s|
    s.investigation ||= Factory(:min_investigation, contributor: s.contributor, policy: s.policy.try(:deep_copy))
  end
end

Factory.define(:max_study, parent: :min_study) do |f|
  f.title "A Maximal Study"
  f.description "The Study of many things"
  f.discussion_links { [Factory.build(:discussion_link, label:'Slack')] }
  f.experimentalists "Wet lab people"
  f.other_creators "Marie Curie"
  f.after_build do |s|
    s.assays = [Factory(:max_assay, contributor: s.contributor, policy: Factory(:public_policy))]
  end
  f.assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: Factory(:person, first_name: 'Some', last_name: 'One'))] }
end
