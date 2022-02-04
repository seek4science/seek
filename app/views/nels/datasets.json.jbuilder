json.array! @datasets do |dataset|
  json.id "dataset#{dataset['id']}"
  json.text dataset['name']
  json.parent "project#{params[:id]}"
  json.data do
    json.id dataset['id']
    json.project_id params[:id]
  end
end

@datasets.each do |dataset|
  json.array! dataset['subtypes'].split(',') do |subtype|
    json.id "#{subtype}#{dataset['id']}"
    json.text subtype
    json.parent "dataset#{dataset['id']}"
    json.data do
      json.id "#{subtype}#{dataset['id']}"
      json.project_id params[:id]
      json.dataset_id dataset['id']
    end
  end
end