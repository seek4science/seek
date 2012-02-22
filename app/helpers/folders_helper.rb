module FoldersHelper
  def folder_asset_item_tooltip asset
    text="<h3>#{h(asset.title)}</h3>"
    text << "<p><b>Description: </b><em>#{text_or_not_specified(asset.description)}</em></p>" if asset.respond_to?("description")
    text << "<p><em>#{text_or_not_specified(asset.abstract)}</em></p>" if asset.respond_to?("abstract")

    if asset.respond_to?("creators")
      text << "<p><b>Creators: </b>"+text_or_not_specified(join_with_and(asset.creators.collect{|c| c.name}))+"</p>"
    end
    text << "<p><b>Filename: </b>#{asset.original_filename}" if asset.respond_to?("original_filename")

    tooltip_title_attrib(text, 2000)
  end

  def folder_node_creation_javascript root_folders, root="root",map_var="elementFolderIds"
    js="";
    root_folders.each do |folder|
      var = "node#{folder.id}"
      js << "var #{var} = new YAHOO.widget.TextNode({"
      js << "label: '#{folder.label}',"
      js << "href: 'javascript: folder_clicked(#{folder.id},#{folder.project.id});',"
      js << "expanded: 'true'"
      js << "},#{root});"
      js << "\n\t"
      js << "#{map_var}[#{var}.labelElId]= #{folder.id};" << "\n\t"

      js << folder_node_creation_javascript(folder.children,var)
    end

    js
  end

end
