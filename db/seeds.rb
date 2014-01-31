#encoding: utf-8
# Seeds the database with BioVeL-specific data

# Seeds projects
biovel = Project.find_by_name('BioVeL') || Project.create(:name => 'BioVeL')
puts 'Seeded the BioVeL project.'

# Seeds institutions
institutions = [{:name => 'University of Manchester', :country => 'United Kingdom'},
{:name => 'Cardiff University', :country => 'United Kingdom'},
{:name => 'Centro de Referência em Informação Ambiental', :country => 'Brazil'},
{:name => 'Foundation for Research on Biodiversity', :country => 'France'},
{:name => 'Fraunhofer-Gesellschaft Institute IAIS', :country => 'Germany'},
{:name => 'Berlin Botanical Gardens and Botanical Museum', :country => 'Germany'},
{:name => 'Hungarian Academy of Sciences Institute of Ecology and Botany', :country => 'Hungary'},
{:name => 'Max Planck Society, MPI for Marine Microbiology', :country => 'Germany'},
{:name => 'National Institute of Nuclear Physics', :country => 'Italy'},
{:name => 'National Research Council: Institute for Biomedical Technologies and Institute of Biomembrane and Bioenergetics', :country => 'Italy'},
{:name => 'Netherlands Centre for Biodiversity ', :country => 'Netherlands'},
{:name => 'Stichting European Grid Initiative', :country => 'Netherlands'},
{:name => 'University of Amsterdam', :country => 'Netherlands'},
{:name => 'University of Eastern Finland', :country => 'Finland'},
{:name => 'University of Gothenburg', :country => 'Sweden'}]

count = 0
institutions.each do |inst|
  institution = Institution.where(:name => inst[:name], :country => inst[:country]).first ||
                Institution.create(:name => inst[:name], :country => inst[:country])
  unless WorkGroup.where(:project_id => biovel.id, :institution_id => institution.id).exists?
    WorkGroup.create(:project_id => biovel.id, :institution_id => institution.id)
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

# Seeds workflow input port types
workflow_input_port_types = [WorkflowInputPortType::DATA, WorkflowInputPortType::PARAMETER]

count = 0
workflow_input_port_types.each do |type|
  unless WorkflowInputPortType.find_by_name(type)
    WorkflowInputPortType.create!(name: type)
    count += 1
  end
end

puts "Seeded #{count} workflow input port types."

# Seeds workflow output port types
workflow_output_port_types = [WorkflowOutputPortType::RESULT, WorkflowOutputPortType::ERROR_LOG]
count = 0
workflow_output_port_types.each do |type|
  unless WorkflowOutputPortType.find_by_name(type)
    WorkflowOutputPortType.create!(name: type)
    count += 1
  end
end

puts "Seeded #{count} workflow output port types."

# Admin User
admin_inst = {:name => 'University of Manchester', :country => 'United Kingdom'}

admin_institution = Institution.where(:name => admin_inst[:name], :country => admin_inst[:country]).first ||
    Institution.create(:name => admin_inst[:name], :country => admin_inst[:country])

admin_workgroup = WorkGroup.where(:project_id => biovel.id, :institution_id => admin_institution.id).first ||
    WorkGroup.create(:project_id => biovel.id, :institution_id => admin_institution.id)

admin_user = User.find_by_login('admin') ||
    User.create(:login => 'admin', :email => 'admin@example.com', :password => 'admin',
                                                                  :password_confirmation => 'admin')

admin_user.activate
admin_user.person ||= Person.create(:first_name => 'Admin', :last_name => 'User', :email => 'admin@example.com')
admin_user.save
admin_user.person.work_groups << admin_workgroup
admin_person = admin_user.person
admin_person.add_roles(['gatekeeper', 'project_manager'])
admin_person.save

puts 'Seeded the Admin user.'

# Guest User
guest_project = Project.find_by_name('BioVeL Portal Guests') || Project.create(:name => 'BioVeL Portal Guests')

guest_inst = {:name => 'Example Institution', :country => 'United Kingdom'}

guest_institution = Institution.where(:name => guest_inst[:name], :country => guest_inst[:country]).first ||
    Institution.create(:name => guest_inst[:name], :country => guest_inst[:country])

guest_workgroup = WorkGroup.where(:project_id => guest_project.id, :institution_id => guest_institution.id).first ||
    WorkGroup.create(:project_id => guest_project.id, :institution_id => guest_institution.id)

guest_user = User.find_by_login('guest') ||
    User.create(:login => 'guest', :email => 'guest@example.com', :password => 'guest',
                                                                  :password_confirmation => 'guest')

guest_user.activate
guest_user.person ||= Person.create(:first_name => 'Guest', :last_name => 'User', :email => 'guest@example.com')
guest_user.save
guest_user.person.work_groups << guest_workgroup
puts 'Seeded the Guest user.'

puts "Done."
