# Investigation
Factory.define(:investigation, class: Investigation) do |f|
  f.projects { [Factory.build(:project)] }
  f.sequence(:title) { |n| "Investigation#{n}" }
  f.association :contributor, factory: :person
  f.after_create do |p|
    y = p.save
  end
end

Factory.define(:min_investigation, class: Investigation) do |f|
  f.title "A Minimal Investigation"
  f.projects { [Factory.build(:min_project)] }
end

Factory.define(:max_investigation, class: Investigation) do |f|
  f.title "A Maximal Investigation"
  f.other_creators "Max Blumenthal, Ed Snowden"
  f.projects { [Factory.build(:project)] }
  f.description "Investigation of the Human Genome"
  f.studies {[Factory(:max_study, policy: Factory(:public_policy))]}
end
