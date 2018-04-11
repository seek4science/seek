class CreateDocumentVersions < ActiveRecord::Migration
  def change
    create_table :document_versions do |t|
      t.references :document, index: true
      t.integer :version
      t.text :revision_comments

      t.text :title
      t.text :description
      t.references :contributor, polymorphic: true, index: true
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
