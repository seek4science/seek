class CreateInvestigations < ActiveRecord::Migration
  def self.up
    create_table :investigations do |t|
      t.string :title
      t.text :description
      t.integer :project_id

      t.timestamps
    end
  end

  def self.down
    drop_table :investigations
  end
end
