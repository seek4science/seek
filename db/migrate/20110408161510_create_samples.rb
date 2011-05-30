class CreateSamples < ActiveRecord::Migration
  def self.up
    create_table :samples do |t|
      t.string :title
      t.integer :specimen_id
      t.string :lab_internal_number
      t.datetime :donation_date
      t.string :explantation
      t.string :comments
      t.string :first_letter
      t.integer :policy_id

      t.timestamps
    end
  end

  def self.down
    drop_table :samples
  end
end
