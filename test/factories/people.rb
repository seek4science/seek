# Person
Factory.define(:min_person, class: Person) do |f|
  f.email "minimal_person@email.com"
  f.last_name "Minimal"
end

Factory.define(:max_person, class: Person) do |f|
  f.first_name "Maximilian"
  f.last_name "Maxi-Mum"
  f.description "A person with all possible details"
  f.web_page "http://www.website.com"
  f.orcid "https://orcid.org/0000-0001-9842-9718"
  f.email "maximal_person@email.com"
  f.phone "34-167-552266"
  f.skype_name "myskypename"
  f.association :user, factory: :activated_user, login: 'max_person_user'
  f.group_memberships { [Factory.build(:group_membership)] }
  f.after_create do |p|
    p.contributed_assays = [Factory(:min_assay, contributor: p, policy: Factory(:public_policy))]
    p.created_sops = [Factory(:sop, contributor: p, policy: Factory(:public_policy))]
    p.created_models = [Factory(:model, contributor: p, policy: Factory(:public_policy))]
    p.created_presentations = [Factory(:presentation, contributor: p, policy: Factory(:public_policy))]
    p.created_data_files = [Factory(:data_file, contributor: p, policy: Factory(:public_policy))]
    p.created_publications = [Factory(:publication, contributor: p)]
    p.created_documents = [Factory(:public_document, contributor: p)]
    p.reload
  end
end

Factory.define(:brand_new_person, class: Person) do |f|
  f.sequence(:email) { |n| "test#{n}@test.com" }
  f.sequence(:first_name) { |n| "Person#{n}" }
  f.last_name 'Last'
end

Factory.define(:person_in_project, parent: :brand_new_person) do |f|
  f.ignore do
    project { Factory(:project) }
    institution { Factory(:institution) }
  end
  f.group_memberships { [Factory.build(:group_membership, work_group: Factory(:work_group, project: project, institution: institution))] }
  f.after_create do |p|
    p.reload
  end
end

Factory.define(:person_not_in_project, parent: :brand_new_person) do |f|
  f.association :user, factory: :activated_user
end

Factory.define(:not_activated_person, parent: :brand_new_person) do |f|
  f.association :user, factory: :brand_new_user
end

Factory.define(:person_in_multiple_projects, parent: :brand_new_person) do |f|
  f.association :user, factory: :activated_user
  f.group_memberships { [Factory.build(:group_membership), Factory.build(:group_membership), Factory.build(:group_membership)] }
  f.after_create do |p|
    p.reload
  end
end

Factory.define(:person, parent: :person_in_project) do |f|
  f.association :user, factory: :activated_user
end

Factory.define(:admin, parent: :person) do |f|
  f.is_admin true
end

Factory.define(:pal, parent: :person) do |f|
  f.after_create do |p|
    p.assign_role(:pal, p.group_memberships.first.project).save!
  end
end

Factory.define(:asset_housekeeper, parent: :person) do |f|
  f.after_create do |p|
    p.assign_role(:asset_housekeeper, p.group_memberships.first.project).save!
  end
end

Factory.define(:project_administrator, parent: :person) do |f|
  f.after_create do |p|
    p.assign_role(:project_administrator, p.group_memberships.first.project).save!
  end
end

Factory.define(:programme_administrator_not_in_project, parent: :person_not_in_project) do |f|
  f.after_create do |p|
    programme = Factory(:programme)
    p.assign_role(:programme_administrator, programme).save!
  end
end

Factory.define(:programme_administrator, parent: :person) do |f|
  f.after_create do |p|
    programme = Factory(:programme, projects: [p.group_memberships.first.project])
    p.assign_role(:programme_administrator, programme).save!
  end
end

Factory.define(:asset_gatekeeper, parent: :person) do |f|
  f.after_create do |p|
    p.assign_role(:asset_gatekeeper, p.group_memberships.first.project).save!
  end
end

Factory.define(:former_project_person, parent: :person) do |f|
  f.after_build do |p|
    p.group_memberships.first.time_left_at = 1.day.ago
  end
end

Factory.define(:future_former_project_person, parent: :person) do |f|
  f.after_build do |p|
    p.group_memberships.first.time_left_at = 1.week.from_now
  end
end

# AssetsCreator
Factory.define :assets_creator do |f|
  f.association :asset, factory: :data_file
  f.association :creator, factory: :person_in_project
end

Factory.define(:avatar) do |f|
  f.original_filename "#{Rails.root}/test/fixtures/files/file_picture.png"
  f.image_file File.new("#{Rails.root}/test/fixtures/files/file_picture.png", 'rb')
  f.association :owner, factory: :person
end