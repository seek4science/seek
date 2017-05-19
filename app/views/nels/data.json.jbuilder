json.array! @data do |data|
  json.id "data#{data['id']}"
  json.text data['name']
  json.parent "dataset#{params[:id]}"
  json.data do
    json.id data['id']
    json.project_id params[:project_id]
    json.dataset_id params[:id]
  end
end
