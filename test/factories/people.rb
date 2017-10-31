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
  f.roles_mask 2
  f.after_build do |pal|
    Factory(:pal_position) if ProjectPosition.pal_position.nil?
    pal.group_memberships.first.project_positions << ProjectPosition.pal_position
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

# AssetsCreator
Factory.define :assets_creator do |f|
  f.association :asset, factory: :data_file
  f.association :creator, factory: :person_in_project
end
