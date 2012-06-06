class CreatePhenotypes < ActiveRecord::Migration
  def self.up
    create_table :phenotypes do |t|
      t.text :description
      t.text :comment
      t.integer :strain_id

      t.timestamps
    end
  end

  def self.down
    drop_table :phenotypes
  end
end
