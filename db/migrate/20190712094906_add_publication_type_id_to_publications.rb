class AddPublicationTypeIdToPublications < ActiveRecord::Migration
  def change
    add_column :publications, :publication_type_id, :int
  end
end
