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
    discussion_links { [FactoryBot.build(:discussion_link, label:'Slack')] }
    web_page { "http://www.taverna.org.uk" }
    wiki_page { "http://www.mygrid.org.uk" }
    default_license { "Other (Open)" }
    start_date { "2010-01-01" }
    end_date { "2014-06-21" }
    use_default_policy { "true" }
    avatar
    programme
  
    investigations {[FactoryBot.create(:max_investigation, policy: FactoryBot.create(:public_policy))]}
    data_files {[FactoryBot.create(:data_file, policy: FactoryBot.create(:public_policy))]}
    sops {[FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))]}
    models {[FactoryBot.create(:model, policy: FactoryBot.create(:public_policy))]}
    presentations {[FactoryBot.create(:presentation, policy: FactoryBot.create(:public_policy))]}
    publications {[FactoryBot.create(:publication, policy: FactoryBot.create(:public_policy))]}
    events {[FactoryBot.create(:event, policy: FactoryBot.create(:public_policy))]}
    documents {[FactoryBot.create(:document, policy: FactoryBot.create(:public_policy))]}
    workflows {[FactoryBot.create(:workflow, policy: FactoryBot.create(:public_policy))]}
    collections {[FactoryBot.create(:collection, policy: FactoryBot.create(:public_policy))]}
    after(:create) do |p|
      member = FactoryBot.create(:person, project: p)
      p.reload
      p.default_policy = FactoryBot.create(:private_policy)
  
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
