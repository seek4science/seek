class CreateOfficialCompounds < ActiveRecord::Migration
  def self.up
    create_table :official_compounds do |t|
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :official_compounds
  end
end
