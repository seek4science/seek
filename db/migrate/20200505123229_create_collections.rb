class CreateCollections < ActiveRecord::Migration[5.2]
  def change
    create_table :collections do |t|
      t.text :title
      t.text :description
      t.references :contributor, index: true
      t.string :first_letter, limit: 1
      t.string :uuid
      t.references :policy
      t.string :doi
      t.string :license
      t.datetime :last_used_at
      t.text :other_creators
      t.timestamps
    end
  end
end
