module FoldersHelper
  def folder_asset_item_tooltip asset
    text="<h3>#{h(asset.title)}</h3>"
    text << "<p><b>Description: </b><em>#{text_or_not_specified(asset.description)}</em></p>" if asset.respond_to?("description")
    text << "<p><em>#{text_or_not_specified(asset.abstract)}</em></p>" if asset.respond_to?("abstract")

    if asset.respond_to?("creators")
      text << "<p><b>Contributors: </b>"+text_or_not_specified(join_with_and(asset.creators.collect{|c| c.name}))+"</p>"
    end
    text << "<p><b>Filename: </b>#{asset.original_filename}" if asset.respond_to?("original_filename")

    tooltip(text)
  end

  def folder_node_creation_javascript root_folders, root="root",map_var="elementFolderIds"
    js="";
    root_folders.each do |folder|
      var = "node#{folder.id}"
      js << "var #{var} = new YAHOO.widget.TextNode({"
      js << "label: '#{h(folder.label)}',"
      js << "href: 'javascript: folder_clicked(\"#{folder.id}\",#{folder.project.id});',"
      js << "expanded: 'true'"
      js << "},#{root});"
      js << "\n\t"
      js << "#{map_var}[#{var}.labelElId]= '#{folder.id}';" << "\n\t"

      js << folder_node_creation_javascript(folder.children,var)
    end

    js.html_safe
  end

  #returns the last opened folder_id for the given project according to the decoded cookie :folder_browsed_json
  def last_opened_folder_id project
    cooky = cookies[:folder_browsed_json]
    cooky||={}.to_json
    cooky = ActiveSupport::JSON.decode(cooky)
    folder_id = cooky[project.id.to_s]

    if folder_id
      folder_id = nil if !ProjectFolder.find_by_id(folder_id)
    end

    folder_id ||= ProjectFolder.new_items_folder(project).try(:id)
    folder_id
  end


  def initial_folder project
    last_id = last_opened_folder_id(project)
    folder = ProjectFolder.find_by_id(last_id)
  end

end
