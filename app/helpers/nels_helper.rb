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

  def nels_locked_dataset_glyph
    'glyphicon glyphicon-lock'
  end

  def nels_locked_dataset_icon
    content_tag(:span, '', class: nels_locked_dataset_glyph).html_safe
  end

  def show_nels_button_for_assay?(assay)
    Seek::Config.nels_enabled &&
      current_user && current_user.person && assay.can_edit? &&
      current_user.person.projects.any?(&:nels_enabled) &&
      assay.projects.any?(&:nels_enabled)
  end

  def show_nels_button_for_project?(project)
    current_user &&
      Seek::Config.nels_enabled &&
      project.nels_enabled &&
      project.has_member?(current_user)
  end

end