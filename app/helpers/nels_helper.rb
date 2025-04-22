module NelsHelper

  NORMAL_USER_MEMBERSHIP = 4

  def nels_file_details_json(items_hash, project_name, dataset_name, subtype_name)
    # download_file,project_id: @project_id, dataset_id: @dataset_id, subtype_name: , path: file_item["path"], filename: file_item['name']
    items_hash.collect do |item|
      {
        path: item['path'],
        filename: item['name'],
        project_id: item['project_id'],
        dataset_id: item['dataset_id'],
        project_name: project_name,
        dataset_name: dataset_name,
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

  def is_nels_dataset_locked?(dataset, project)
    dataset['islocked'] || project['membership_type'] == NORMAL_USER_MEMBERSHIP
  end

  def subtype_path_breadcrumbs(subtype_path, full_path, project_id, dataset_id, subtype_name)
    current_path = full_path.chomp(subtype_path).chomp('/')
    root_link = link_to('<root>', '#', class:'nels-folder', 'data-path':current_path, 'data-project-id':project_id, 'data-dataset-id':dataset_id, 'data-subtype':subtype_name)
    sub_links = subtype_path.split('/').collect do |fragment|
      current_path = "#{current_path}/#{fragment}"
      link_to(fragment, '#', class:'nels-folder', 'data-path':current_path, 'data-project-id':project_id, 'data-dataset-id':dataset_id, 'data-subtype':subtype_name)
    end
    ([root_link]+sub_links).join(' / ').html_safe
  end

  def nels_folder_icon
    icon_tag('folder_avatar', size:48)
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