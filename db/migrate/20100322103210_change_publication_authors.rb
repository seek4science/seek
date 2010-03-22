class ChangePublicationAuthors < ActiveRecord::Migration
  def self.up
    drop_table :publication_authors
    create_table :publication_authors do |t|
      t.string :first_name
      t.string :last_name
      t.integer :publication_id
      t.timestamps
    end
  end

  def self.down
    drop_table :publication_authors
    create_table :publication_authors do |t|
      t.integer :author_id
      t.integer :publication_id
      t.timestamps
    end
  end
end
