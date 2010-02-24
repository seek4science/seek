class CreateRelationshipTypes < ActiveRecord::Migration
  def self.up
    create_table :relationship_types do |t|
      t.string   :title
      t.text     :description
      t.timestamps
    end
  end

  def self.down
    drop_table :relationship_types
  end
end
