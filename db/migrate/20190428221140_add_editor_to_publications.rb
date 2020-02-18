class AddEditorToPublications < ActiveRecord::Migration[4.2]
  def change
    add_column :publications, :editor, :string
  end
end
