class AddBooktitleToPublications < ActiveRecord::Migration
  def change
    add_column :publications, :booktitle, :string
  end
end
