class CreateProgrammes < ActiveRecord::Migration
  def change
    create_table :programmes do |t|
      t.string :title
      t.text :description
      t.integer :avatar_id
      t.string :web_page
      t.string :first_letter, :limit=>1
      t.string :uuid

      t.timestamps
    end
  end
end
