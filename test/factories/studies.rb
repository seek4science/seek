# Study
Factory.define(:study) do |f|
  f.sequence(:title) { |n| "Study#{n}" }
  f.association :investigation
  f.association :contributor, factory: :person
end

Factory.define(:min_study, class: Study) do |f|
  f.title "A Minimal Study"
  f.association :investigation, factory: :min_investigation
end

Factory.define(:max_study, class: Study) do |f|
  f.title "A Maximal Study"
  f.description "The Study of many things"
  f.experimentalists "Wet lab people"
  f.association :investigation, factory: :investigation
  f.assays {[Factory(:assay, policy: Factory(:public_policy))]}
end
