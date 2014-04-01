json.partial! "info", :run => @run

json.inputs @run.inputs do |input|
  json.partial! "port", :port => input
end
