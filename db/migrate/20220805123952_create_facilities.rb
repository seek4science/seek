class CreateFacilities < ActiveRecord::Migration[6.1]
  def change
    create_table :facilities do |t|
      t.text :title
      t.text :description

      t.timestamps
    end
  end
end
