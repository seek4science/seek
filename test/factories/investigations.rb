# Investigation
Factory.define(:investigation, class: Investigation) do |f|
  f.with_project_contributor
  f.sequence(:title) { |n| "Investigation#{n}" }
end

Factory.define(:min_investigation, class: Investigation) do |f|
  f.with_project_contributor
  f.title "A Minimal Investigation"
end

Factory.define(:max_investigation, parent: :min_investigation) do |f|
  f.with_project_contributor
  f.title "A Maximal Investigation"
  f.other_creators "Max Blumenthal, Ed Snowden"
  f.description "Investigation of the Human Genome"
  f.after_build do |i|
    i.studies = [Factory(:max_study, contributor: i.contributor, policy: Factory(:public_policy))]
  end
end
