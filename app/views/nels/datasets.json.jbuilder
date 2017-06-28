json.array! @datasets do |dataset|
  json.id "dataset#{dataset['id']}"
  json.text dataset['name']
  json.parent "project#{params[:id]}"
  json.data do
    json.id dataset['id']
    json.project_id params[:id]
  end
end
