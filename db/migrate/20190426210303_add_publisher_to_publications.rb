class AddPublisherToPublications < ActiveRecord::Migration
  def change
    add_column :publications, :publisher, :string
  end
end
