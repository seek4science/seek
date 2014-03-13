workflow_title = TavernaPlayer.workflow_proxy.title(@workflow) || "None"
workflow_inputs = TavernaPlayer.workflow_proxy.inputs(@workflow)

json.run do
  json.workflow_id @run.workflow_id
  json.name workflow_title
  json.inputs_attributes do
    json.array! workflow_inputs do |input|
      json.name input[:name]
      json.value input[:example]
    end
  end
end
