class CreateSourceAttributes < ActiveRecord::Migration[5.2]
  def change
    create_table :source_attributes do |t|
      t.references :source_type, index: { unique: false }, null: false
      t.string :name
      t.text :IRI
      t.boolean :required
      t.string :short_name
      t.text :description
    end
  end
end
