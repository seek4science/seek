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
  f.discussion_links { [Factory.build(:discussion_link, label:'Slack')] }
  f.web_page "http://www.taverna.org.uk"
  f.wiki_page "http://www.mygrid.org.uk"
  f.default_license "Other (Open)"
  f.start_date "2010-01-01"
  f.end_date "2014-06-21"
  f.use_default_policy "true"
  f.avatar
  f.programme

  f.investigations {[Factory(:max_investigation, policy: Factory(:public_policy))]}
  f.data_files {[Factory(:data_file, policy: Factory(:public_policy))]}
  f.sops {[Factory(:sop, policy: Factory(:public_policy))]}
  f.models {[Factory(:model, policy: Factory(:public_policy))]}
  f.presentations {[Factory(:presentation, policy: Factory(:public_policy))]}
  f.publications {[Factory(:publication, policy: Factory(:public_policy))]}
  f.events {[Factory(:event, policy: Factory(:public_policy))]}
  f.documents {[Factory(:document, policy: Factory(:public_policy))]}
  f.workflows {[Factory(:workflow, policy: Factory(:public_policy))]}
  f.after_create do |p|
    member = Factory(:person, project: p)
    p.reload
    p.default_policy = Factory(:private_policy)

    User.with_current_user member.user do
      p.edam_topics = ['Biomedical science','Chemistry']
    end if SampleControlledVocab::SystemVocabs.edam_topics_controlled_vocab

    p.save!
  end
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
