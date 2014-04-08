workflow_title = @workflow_version.title || "None"
workflow_inputs = @workflow_version.input_ports

json.run do
  json.workflow_id @run.workflow_id
  json.workflow_version @run.workflow_version
  json.name workflow_title
  unless workflow_inputs.empty?
    json.inputs_attributes do
      json.array! workflow_inputs do |input|
        json.name input[:name]
        json.value input[:example_value]
      end
    end
  end
end
