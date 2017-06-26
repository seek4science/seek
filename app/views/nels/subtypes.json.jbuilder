json.array! @dataset['subtypes'] do |subtype|
  json.id "dataset#{@dataset['id']}_#{subtype}"
  json.text subtype
  json.parent "dataset#{params[:id]}"
  json.icon asset_path('famfamfam_silk/page.png')
  json.data do
    json.id "#{@dataset['id']}_#{subtype}"
    json.project_id params[:project_id]
    json.dataset_id params[:id]
  end
end
