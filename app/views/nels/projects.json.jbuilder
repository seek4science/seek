json.array! @projects do |project|
  json.id "project#{project['id']}"
  json.text project['name']
  json.parent '#'
  json.icon nels_project_glyph
  json.state do
    json.opened true
    json.loaded false
  end
  json.data do
    json.id project['id']
    json.contact_person project['contact_person']
    json.name project['name']
    json.description project['description']
    json.created_at project['created_at']
  end
end
