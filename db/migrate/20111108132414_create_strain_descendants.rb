class CreateStrainDescendants < ActiveRecord::Migration
  def self.up
    create_table :strain_descendants ,:id=> false do |t|
      t.integer :ancestor_id
      t.integer :descendant_id
    end
  end

  def self.down
    drop_table :strain_descendants
  end
end
