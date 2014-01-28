class ChangeScales < ActiveRecord::Migration
  def change
    change_table :scales do |t|
      t.string :key
      t.integer :pos, :default => 1
      t.string :image_name
    end

  end
end
