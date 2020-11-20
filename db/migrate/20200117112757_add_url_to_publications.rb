class AddUrlToPublications < ActiveRecord::Migration[5.2]
  def change
    add_column :publications, :url, :string
  end
end
