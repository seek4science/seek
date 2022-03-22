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
  f.group_memberships { [Factory.build(:group_membership)] }
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
  f.ignore do
    project { Factory(:project) }
    institution { Factory(:institution) }
  end
  f.group_memberships { [Factory.build(:group_membership, work_group: Factory(:work_group, project: project, institution: institution))] }
  f.association :user, factory: :activated_user
end

Factory.define(:admin, parent: :person) do |f|
  f.is_admin true
end

Factory.define(:pal, parent: :person) do |f|
  f.roles_mask 2
  f.after_build do |pal|
    Factory(:admin_defined_role_project, project: pal.projects.first, person: pal, role_mask: 2)
    pal.roles_mask = 2
  end
end

Factory.define(:asset_housekeeper, parent: :person) do |f|
  f.after_build do |am|
    Factory(:admin_defined_role_project, project: am.projects.first, person: am, role_mask: 8)
    am.roles_mask = 8
  end
end

Factory.define(:project_administrator, parent: :person) do |f|
  f.after_build do |pm|
    Factory(:admin_defined_role_project, project: pm.projects.first, person: pm, role_mask: 4)
    pm.roles_mask = 4
  end
end

Factory.define(:programme_administrator_not_in_project, parent: :person_not_in_project) do |f|
  f.after_build do |pm|
    programme = Factory(:programme)
    Factory(:admin_defined_role_programme, programme: programme, person: pm, role_mask: 32)
    pm.roles_mask = 32
  end
end

Factory.define(:programme_administrator, parent: :project_administrator) do |f|
  f.after_build do |pm|
    programme = Factory(:programme, projects: [pm.projects.first])
    Factory(:admin_defined_role_programme, programme: programme, person: pm, role_mask: 32)
    pm.roles_mask = 32
  end
end

Factory.define(:asset_gatekeeper, parent: :person) do |f|
  f.after_build do |gk|
    Factory(:admin_defined_role_project, project: gk.projects.first, person: gk, role_mask: 16)
    gk.roles_mask = 16
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