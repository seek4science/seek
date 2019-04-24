class CreateScales < ActiveRecord::Migration
  def change
    create_table :scales do |t|
      t.string :title
      t.string :key
      t.integer :pos, :default=>1
      t.string :image_name

      t.timestamps
    end unless data_source_exists?('scales')
  end
end
