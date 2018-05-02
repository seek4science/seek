# Study
Factory.define(:study) do |f|
  f.sequence(:title) { |n| "Study#{n}" }
  f.association :contributor, factory: :person
  f.after_build do |s|
    s.investigation ||= Factory(:investigation, contributor: s.contributor)
  end
end

Factory.define(:min_study, class: Study) do |f|
  f.title "A Minimal Study"
  f.association :investigation, factory: :investigation
end

Factory.define(:max_study, class: Study) do |f|
  f.title "A Maximal Study"
  f.description "The Study of many things"
  f.experimentalists "Wet lab people"
  f.other_creators "Marie Curie"
  f.association :investigation, factory: :investigation
  f.assays {[Factory(:max_assay, policy: Factory(:public_policy))]}
end
