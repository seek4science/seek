# Project
Factory.define(:project) do |f|
  f.sequence(:title) { |n| "A Project: -#{n}" }
end

Factory.define(:min_project, class: Project) do |f|
  f.title "A Minimal Project"
end

Factory.define(:max_project, class: Project) do |f|
  f.title "A Maximal Project"
  f.description "A Taverna project"
  f.web_page "http://www.taverna.org.uk"
  f.wiki_page "http://www.mygrid.org.uk"
end

# WorkGroup
Factory.define(:work_group) do |f|
  f.association :project
  f.association :institution
end

# GroupMembership
Factory.define(:group_membership) do |f|
  f.association :work_group
end
