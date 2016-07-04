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
