json.partial! "info", :run => @run

json.status_message @run.status_message

json.inputs @run.inputs do |input|
  json.partial! "port", :port => input
end

json.outputs @run.outputs do |output|
  json.partial! "port", :port => output
end

if @run.outputs.size > 0
  json.outputs_zip @run.results.url
end

unless @run.log.blank?
  json.log @run.log.url
end

unless @interaction.nil?
  json.interaction do
    json.serial @interaction.serial
    json.uri interaction_redirect(@interaction)
    json.data @interaction.data
    json.reply_uri "#{run_url(@run)}/interaction/#{@interaction.serial}"
  end
end
