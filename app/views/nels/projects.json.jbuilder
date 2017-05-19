json.array! @projects do |project|
  json.id "project#{project['id']}"
  json.text project['name']
  json.parent '#'
  json.state do
    json.loaded false
  end
  json.data do
    json.id project['id']
  end
end
