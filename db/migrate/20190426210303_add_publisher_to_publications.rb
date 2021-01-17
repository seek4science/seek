class AddPublisherToPublications < ActiveRecord::Migration[4.2]
  def change
    add_column :publications, :publisher, :string
  end
end
