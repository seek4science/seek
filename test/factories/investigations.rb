# Investigation
Factory.define(:investigation, class: Investigation) do |f|
  f.with_project_contributor
  f.sequence(:title) { |n| "Investigation#{n}" }
end

Factory.define(:public_investigation, parent: :investigation) do |f|
  f.policy { Factory(:public_policy) }
end

Factory.define(:investigation_with_study_and_assay, parent: :investigation) do |f|
  f.studies { [Factory(:study_with_assay)] }
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
  f.discussion_links { [Factory.build(:discussion_link, label:'Slack')] }
  f.after_build do |i|
    i.studies = [Factory(:max_study, contributor: i.contributor, policy: Factory(:public_policy))]
  end
  f.assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: Factory(:person, first_name: 'Some', last_name: 'One'))] }
end
