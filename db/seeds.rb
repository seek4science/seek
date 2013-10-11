# Seeds the database with BioVeL-specific data

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
