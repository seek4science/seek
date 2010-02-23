class CreateTechnologyTypes < ActiveRecord::Migration
  
  def self.up
    create_table :technology_types do |t|
      t.string :title

      t.timestamps
    end
  end

  def self.down
    drop_table :technology_types
  end

end
