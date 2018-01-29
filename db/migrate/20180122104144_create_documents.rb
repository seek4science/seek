class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.text :title
      t.text :description
      t.references :contributor, polymorphic: true, index: true
      t.integer :version
      t.string :first_letter, limit: 1
      t.string :uuid
      t.references :policy
      t.string :doi
      t.string :license
      t.datetime :last_used_at
      t.timestamps
    end
  end
end
