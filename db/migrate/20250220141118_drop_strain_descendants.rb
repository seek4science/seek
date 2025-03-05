class DropStrainDescendants < ActiveRecord::Migration[7.2]
  def change
    drop_table :strain_descendants, id: false do |t|
      t.integer :ancestor_id
      t.integer :descendant_id
    end
  end
end
