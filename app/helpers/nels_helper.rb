module NelsHelper

  def nels_file_details_json(items_hash, subtype_name)
    # download_file,project_id: @project_id, dataset_id: @dataset_id, subtype_name: , path: file_item["path"], filename: file_item['name']
    items_hash.collect do |item|
      {
        path: item['path'],
        filename: item['name'],
        project_id: item['project_id'],
        dataset_id: item['dataset_id'],
        subtype_name: subtype_name
      }
    end
  end

  def nels_project_glyph
    'glyphicon glyphicon-book'
  end

  def nels_dataset_glyph
    'glyphicon glyphicon-tags'
  end

  def nels_subtype_glyph
    'glyphicon glyphicon-tag'
  end

end