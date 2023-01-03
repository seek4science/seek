class RenameToolAnnotationsToBioToolsLinks < ActiveRecord::Migration[6.1]
  def change
    rename_index :tool_annotations, :index_tool_annotations_on_resource,
                 :index_bio_tools_links_on_resource
    rename_table :tool_annotations, :bio_tools_links
  end
end
