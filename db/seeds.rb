#encoding: utf-8
# Seeds the database with BioVeL-specific data

# Seeds projects
Project.delete_all
project = Project.create(:name => 'BioVeL')
puts 'Seeded the BioVeL project.'

# Seeds institutions
Institution.delete_all

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
{:name => 'Netherlands Centre for Biodiversity ', :country => 'The Netherlands'},
{:name => 'Stichting European Grid Initiative', :country => 'The Netherlands'},
{:name => 'University of Amsterdam', :country => 'The Netherlands'},
{:name => 'University of Eastern Finland', :country => 'Finland'},
{:name => 'University of Gothenburg', :country => 'Sweden'}]

institutions.each do |inst|
  institution = Institution.create(:name => inst[:name], :country => inst[:country])
  WorkGroup.create(:project => project, :institution => institution)
end

puts 'Seeded 15 BioVeL project\'s institutions.'

# Seeds workflow categories
workflow_categories = [WorkflowCategory::TAXONOMIC_REFINEMENT, WorkflowCategory::ENM, WorkflowCategory::METAGENOMICS,
                       WorkflowCategory::PHYLOGENETICS, WorkflowCategory::POPULATION_MODELLING, WorkflowCategory::ECOSYSTEM_MODELLING,
                       WorkflowCategory::OTHER]

WorkflowCategory.delete_all

workflow_categories.each do |category|
  WorkflowCategory.create!(name: category)
end

puts "Seeded #{WorkflowCategory.count} workflow categories."

# Seeds workflow input port types
workflow_input_port_types = [WorkflowInputPortType::DATA, WorkflowInputPortType::PARAMETER]

WorkflowInputPortType.delete_all

workflow_input_port_types.each do |type|
  WorkflowInputPortType.create!(name: type)
end

puts "Seeded #{WorkflowInputPortType.count} workflow input port types."

# Seeds workflow output port types
workflow_output_port_types = [WorkflowOutputPortType::RESULT, WorkflowOutputPortType::ERROR_LOG]

WorkflowOutputPortType.delete_all

workflow_output_port_types.each do |type|
  WorkflowOutputPortType.create!(name: type)
end

puts "Seeded #{WorkflowOutputPortType.count} workflow output port types."

puts "Done."
