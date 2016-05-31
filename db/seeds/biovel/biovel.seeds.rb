# encoding: utf-8
# Seeds the database with BioVeL-specific data

# Seeds projects
biovel = Project.find_by_title('BioVeL') || Project.create(title: 'BioVeL')
puts 'Seeded the BioVeL project.'

# Seeds institutions
institutions = [{ title: 'University of Manchester', country: 'United Kingdom' },
                { title: 'Cardiff University', country: 'United Kingdom' },
                { title: 'Centro de Referência em Informação Ambiental', country: 'Brazil' },
                { title: 'Foundation for Research on Biodiversity', country: 'France' },
                { title: 'Fraunhofer-Gesellschaft Institute IAIS', country: 'Germany' },
                { title: 'Berlin Botanical Gardens and Botanical Museum', country: 'Germany' },
                { title: 'Hungarian Academy of Sciences Institute of Ecology and Botany', country: 'Hungary' },
                { title: 'Max Planck Society, MPI for Marine Microbiology', country: 'Germany' },
                { title: 'National Institute of Nuclear Physics', country: 'Italy' },
                { title: 'National Research Council: Institute for Biomedical Technologies and Institute of Biomembrane and Bioenergetics', country: 'Italy' },
                { title: 'Netherlands Centre for Biodiversity ', country: 'Netherlands' },
                { title: 'Stichting European Grid Initiative', country: 'Netherlands' },
                { title: 'University of Amsterdam', country: 'Netherlands' },
                { title: 'University of Eastern Finland', country: 'Finland' },
                { title: 'University of Gothenburg', country: 'Sweden' }]

count = 0
institutions.each do |inst|
  institution = Institution.where(title: inst[:title], country: inst[:country]).first ||
                Institution.create(title: inst[:title], country: inst[:country])
  unless WorkGroup.where(project_id: biovel.id, institution_id: institution.id).exists?
    WorkGroup.create(project_id: biovel.id, institution_id: institution.id)
    count += 1
  end
end

puts "Seeded #{count} BioVeL project's institutions."

# Seeds workflow categories
workflow_categories = [WorkflowCategory::TAXONOMIC_REFINEMENT, WorkflowCategory::ENM, WorkflowCategory::METAGENOMICS,
                       WorkflowCategory::PHYLOGENETICS, WorkflowCategory::POPULATION_MODELLING, WorkflowCategory::ECOSYSTEM_MODELLING,
                       WorkflowCategory::OTHER]

count = 0
workflow_categories.each do |category|
  unless WorkflowCategory.find_by_name(category)
    WorkflowCategory.create!(name: category)
    count += 1
  end
end

puts "Seeded #{count} workflow categories."

# Admin User
admin_inst = { title: 'University of Manchester', country: 'United Kingdom' }

admin_institution = Institution.where(title: admin_inst[:title], country: admin_inst[:country]).first ||
                    Institution.create(title: admin_inst[:title], country: admin_inst[:country])

admin_workgroup = WorkGroup.where(project_id: biovel.id, institution_id: admin_institution.id).first ||
                  WorkGroup.create(project_id: biovel.id, institution_id: admin_institution.id)

admin_user = User.find_by_login('admin') ||
             User.create(login: 'admin', email: 'admin@example.com', password: 'admin',
                         password_confirmation: 'admin')

admin_user.activate
admin_user.person ||= Person.create(first_name: 'Admin', last_name: 'User', email: 'admin@example.com')
admin_user.save
admin_user.person.work_groups << admin_workgroup
admin_person = admin_user.person
admin_person.add_roles([Seek::Roles::RoleInfo.new(role_name:'asset_gatekeeper', items: biovel),
                        Seek::Roles::RoleInfo.new(role_name:'project_administrator', items: biovel)])
admin_person.save

puts 'Seeded the Admin user.'

# Guest User
guest_project = Project.find_by_title('BioVeL Portal Guests') || Project.create(title: 'BioVeL Portal Guests')

guest_inst = { title: 'Example Institution', country: 'United Kingdom' }

guest_institution = Institution.where(title: guest_inst[:title], country: guest_inst[:country]).first ||
                    Institution.create(title: guest_inst[:title], country: guest_inst[:country])

guest_workgroup = WorkGroup.where(project_id: guest_project.id, institution_id: guest_institution.id).first ||
                  WorkGroup.create(project_id: guest_project.id, institution_id: guest_institution.id)

guest_user = User.find_by_login('guest') ||
             User.create(login: 'guest', email: 'guest@example.com', password: 'guest',
                         password_confirmation: 'guest')

guest_user.activate
guest_user.person ||= Person.create(first_name: 'Guest', last_name: 'User', email: 'guest@example.com')
guest_user.save
guest_user.person.work_groups << guest_workgroup unless guest_user.person.work_groups.include?(guest_workgroup)

puts 'Seeded the Guest user.'

puts 'Finished BioVeL seeding.'
