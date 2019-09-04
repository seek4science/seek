class CreatePublicationTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :publication_types do |t|
      t.string :title
      t.string :key

      t.timestamps null: false
    end
  end
end
