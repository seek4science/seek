FactoryBot.define do
  # Person
  factory(:min_person, class: Person) do
    email { "minimal_person@email.com" }
    last_name { "Minimal" }
  end
  
  factory(:max_person, class: Person) do
    first_name { "Maximilian" }
    last_name { "Maxi-Mum" }
    description { "A person with all possible details" }
    web_page { "http://www.website.com" }
    orcid { "https://orcid.org/0000-0001-9842-9718" }
    email { "maximal_person@email.com" }
    phone { "34-167-552266" }
    skype_name { "myskypename" }
    association :user, factory: :activated_user, login: 'max_person_user'
    group_memberships { [FactoryBot.build(:group_membership)] }
    avatar
    after(:create) do |p|
      p.contributed_assays = [FactoryBot.create(:min_assay, contributor: p, policy: FactoryBot.create(:public_policy))]
      p.created_sops = [FactoryBot.create(:sop, contributor: p, policy: FactoryBot.create(:public_policy))]
      p.created_models = [FactoryBot.create(:model, contributor: p, policy: FactoryBot.create(:public_policy))]
      p.created_presentations = [FactoryBot.create(:presentation, contributor: p, policy: FactoryBot.create(:public_policy))]
      p.created_data_files = [FactoryBot.create(:data_file, contributor: p, policy: FactoryBot.create(:public_policy))]
      p.created_publications = [FactoryBot.create(:publication, contributor: p)]
      p.created_documents = [FactoryBot.create(:public_document, contributor: p)]
      p.created_events = [FactoryBot.create(:event, contributor: p, policy: FactoryBot.create(:public_policy))]
      p.created_collections = [FactoryBot.create(:collection, contributor: p, policy: FactoryBot.create(:public_policy))]
      p.created_workflows = [FactoryBot.create(:workflow, contributor: p, policy: FactoryBot.create(:public_policy))]
      p.annotate_with(['golf', 'fishing'], 'expertise', p)
      p.annotate_with(['fishing rod'], 'tool', p)
      p.save!
      p.reload
    end
  end
  
  factory(:brand_new_person, class: Person) do
    sequence(:email) { |n| "test#{n}@test.com" }
    sequence(:first_name) { |n| "Person#{n}" }
    last_name { 'Last' }
  end
  
  factory(:person_in_project, parent: :brand_new_person) do
    transient do
      project { FactoryBot.create(:project) }
      institution { FactoryBot.create(:institution) }
    end
    group_memberships { [FactoryBot.build(:group_membership, work_group: FactoryBot.create(:work_group, project: project, institution: institution))] }
    after(:create) do |p|
      p.reload
    end
  end
  
  factory(:person_not_in_project, parent: :brand_new_person) do
    association :user, factory: :activated_user
  end
  
  factory(:not_activated_person, parent: :brand_new_person) do
    association :user, factory: :brand_new_user
  end
  
  factory(:person_in_multiple_projects, parent: :brand_new_person) do
    association :user, factory: :activated_user
    group_memberships { [FactoryBot.build(:group_membership), FactoryBot.build(:group_membership), FactoryBot.build(:group_membership)] }
    after(:create) do |p|
      p.reload
    end
  end
  
  factory(:person, parent: :person_in_project) do
    association :user, factory: :activated_user
  end
  
  factory(:admin, parent: :person) do
    is_admin { true }
  end
  
  factory(:pal, parent: :person) do
    after(:create) do |p|
      p.is_pal = true, p.group_memberships.first.project
    end
  end
  
  factory(:asset_housekeeper, parent: :person) do
    after(:create) do |p|
      p.is_asset_housekeeper = true, p.group_memberships.first.project
    end
  end
  
  factory(:project_administrator, parent: :person) do
    after(:create) do |p|
      p.is_project_administrator = true, p.group_memberships.first.project
    end
  end
  
  factory(:programme_administrator_not_in_project, parent: :person_not_in_project) do
    after(:create) do |p|
      programme = FactoryBot.create(:programme)
      p.is_programme_administrator = true, programme
    end
  end
  
  factory(:programme_administrator, parent: :person) do
    after(:create) do |p|
      programme = FactoryBot.create(:programme, projects: [p.group_memberships.first.project])
      p.is_programme_administrator = true, programme
    end
  end
  
  factory(:asset_gatekeeper, parent: :person) do
    after(:create) do |p|
      p.is_asset_gatekeeper = true, p.group_memberships.first.project
    end
  end
  
  factory(:former_project_person, parent: :person) do
    after(:build) do |p|
      p.group_memberships.first.time_left_at = 1.day.ago
    end
  end
  
  factory(:future_former_project_person, parent: :person) do
    after(:build) do |p|
      p.group_memberships.first.time_left_at = 1.week.from_now
    end
  end
  
  # AssetsCreator
  factory :assets_creator do
    association :asset, factory: :data_file
    association :creator, factory: :person_in_project
  end
  
  factory(:avatar) do
    original_filename { "#{Rails.root}/test/fixtures/files/file_picture.png" }
    image_file { File.new("#{Rails.root}/test/fixtures/files/file_picture.png", 'rb') }
    association :owner, factory: :person
  end
end
