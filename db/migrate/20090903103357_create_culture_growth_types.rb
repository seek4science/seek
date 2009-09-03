class CreateCultureGrowthTypes < ActiveRecord::Migration
  def self.up
    create_table :culture_growth_types do |t|
      t.string :title

      t.timestamps
    end
  end

  def self.down
    drop_table :culture_growth_types
  end
end
