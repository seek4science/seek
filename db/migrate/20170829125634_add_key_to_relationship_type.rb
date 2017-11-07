class AddKeyToRelationshipType < ActiveRecord::Migration
  def change
    add_column :relationship_types, :key, :string
  end
end
