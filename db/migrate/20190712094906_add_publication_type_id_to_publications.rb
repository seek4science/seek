class AddPublicationTypeIdToPublications < ActiveRecord::Migration[4.2]
  def change
    add_column :publications, :publication_type_id, :int
  end
end
