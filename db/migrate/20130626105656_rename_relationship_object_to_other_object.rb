class RenameRelationshipObjectToOtherObject < ActiveRecord::Migration
  def change
    rename_column :relationships, :object_id, :other_object_id
    rename_column :relationships, :object_type, :other_object_type
  end
end
