class CreatePublicationAuthors < ActiveRecord::Migration
  def self.up
    create_table :publication_authors do |t|
      t.integer :author_id
      t.integer :publication_id
      t.timestamps
    end
  end

  def self.down
    drop_table :publication_authors
  end
end
