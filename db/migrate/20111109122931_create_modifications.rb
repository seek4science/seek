class CreateModifications < ActiveRecord::Migration
  def self.up
    create_table :modifications do |t|
      t.string :title
      t.string :symbol
      t.text :description
      t.string :position

      t.timestamps
    end
  end

  def self.down
    drop_table :modifications
  end
end
