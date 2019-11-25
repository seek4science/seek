class AddBooktitleToPublications < ActiveRecord::Migration[4.2]
  def change
    add_column :publications, :booktitle, :string
  end
end
