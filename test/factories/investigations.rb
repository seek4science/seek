# Investigation
Factory.define(:investigation, class: Investigation) do |f|
  f.sequence(:title) { |n| "Investigation#{n}" }
  f.association :contributor, factory: :person
  f.after_build do |p|
    p.projects = [p.contributor.person.projects.first] if p.projects.empty?
  end
end

Factory.define(:min_investigation, class: Investigation) do |f|
  f.title "A Minimal Investigation"
  f.after_build do |p|
    project = Factory.build(:min_project)
    p.contributor ||= Factory(:person, project: project)
    p.projects = [project] if p.projects.empty?
  end
end

Factory.define(:max_investigation, parent: :min_investigation) do |f|
  f.title "A Maximal Investigation"
  f.other_creators "Max Blumenthal, Ed Snowden"
  f.description "Investigation of the Human Genome"
  f.after_build do |p|
    p.studies = [Factory(:max_study, contributor: p.contributor, policy: Factory(:public_policy))]
  end
end
