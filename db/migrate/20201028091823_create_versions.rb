class CreateVersions < ActiveRecord::Migration[5.2]
  def change
    create_table :versions do |t|
      t.references :resource, polymorphic: true
      t.integer :version
      t.string :name
      t.text :description
      t.string :target
      t.string :commit
      t.boolean :mutable
      t.text :root_path
      t.timestamps
    end
  end
end
