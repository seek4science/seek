FactoryBot.define do
  # Project
  factory(:project) do
    sequence(:title) { |n| "A Project: -#{n}" }
  end
  
  factory(:min_project, class: Project) do
    title { "A Minimal Project" }
  end
  
  factory(:max_project, class: Project) do
    title { "A Maximal Project" }
    description { "A Taverna project" }
    discussion_links { [Factory.build(:discussion_link, label:'Slack')] }
    web_page { "http://www.taverna.org.uk" }
    wiki_page { "http://www.mygrid.org.uk" }
    default_license { "Other (Open)" }
    start_date { "2010-01-01" }
    end_date { "2014-06-21" }
    use_default_policy { "true" }
    avatar
    programme
  
    investigations {[Factory(:max_investigation, policy: Factory(:public_policy))]}
    data_files {[Factory(:data_file, policy: Factory(:public_policy))]}
    sops {[Factory(:sop, policy: Factory(:public_policy))]}
    models {[Factory(:model, policy: Factory(:public_policy))]}
    presentations {[Factory(:presentation, policy: Factory(:public_policy))]}
    publications {[Factory(:publication, policy: Factory(:public_policy))]}
    events {[Factory(:event, policy: Factory(:public_policy))]}
    documents {[Factory(:document, policy: Factory(:public_policy))]}
    workflows {[Factory(:workflow, policy: Factory(:public_policy))]}
    collections {[Factory(:collection, policy: Factory(:public_policy))]}
    after_create do |p|
      member = Factory(:person, project: p)
      p.reload
      p.default_policy = Factory(:private_policy)
  
      User.with_current_user member.user do
        p.topic_annotations = ['Biomedical science','Chemistry']
      end if SampleControlledVocab::SystemVocabs.topics_controlled_vocab
  
      p.save!
    end
  end
  
  # WorkGroup
  factory(:work_group) do
    association :project
    association :institution
  end
  
  # GroupMembership
  factory(:group_membership) do
    association :work_group
  end
end
