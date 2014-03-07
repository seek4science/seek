json.partial! "info", :run => @run

json.status_message @run.status_message

json.partial! "inputs", :inputs => @run.inputs

if @run.outputs.size > 0
  json.outputs @run.outputs do |output|
    json.name output.name
    json.depth output.depth
    json.type output.metadata[:type]
    json.size output.metadata[:size]
    json.uri run_path(@run) + "/output/#{output.name}"
  end

  json.outputs_zip @run.results.url
end

unless @run.log.blank?
  json.log @run.log.url
end

unless @interaction.nil?
  json.interaction do
    json.serial @interaction.serial
    json.uri interaction_redirect(@interaction)
  end
end
