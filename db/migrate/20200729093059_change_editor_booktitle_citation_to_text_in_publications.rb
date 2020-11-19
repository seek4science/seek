class ChangeEditorBooktitleCitationToTextInPublications < ActiveRecord::Migration[5.2]
    def up
      change_column :publications, :editor, :text
      change_column :publications, :booktitle, :text
      change_column :publications, :citation, :text
    end

    def down
      change_column :publications, :editor, :string
      change_column :publications, :booktitle, :string
      change_column :publications, :citation, :string
    end
end
