class AddEditorToPublications < ActiveRecord::Migration
  def change
    add_column :publications, :editor, :string
  end
end
