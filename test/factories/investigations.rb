# Investigation
Factory.define(:investigation, class: Investigation) do |f|
  f.sequence(:title) { |n| "Investigation#{n}" }
  f.association :contributor, factory: :person
  f.after_build do |i|
    i.projects = [i.contributor.person.projects.first] if i.projects.empty?
  end
end

Factory.define(:min_investigation, class: Investigation) do |f|
  f.title "A Minimal Investigation"
  f.after_build do |i|
    project = Factory(:min_project)
    i.contributor ||= Factory(:person, project: project)
    i.projects = [project] if i.projects.empty?
  end
end

Factory.define(:max_investigation, parent: :min_investigation) do |f|
  f.title "A Maximal Investigation"
  f.other_creators "Max Blumenthal, Ed Snowden"
  f.description "Investigation of the Human Genome"
  f.after_build do |i|
    i.studies = [Factory(:max_study, contributor: i.contributor, policy: Factory(:public_policy))]
  end
end
