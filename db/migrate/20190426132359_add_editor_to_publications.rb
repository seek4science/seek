class AddEditorToPublications < ActiveRecord::Migration
  def change
    add_column :publications, :editor, :strings
  end
end
