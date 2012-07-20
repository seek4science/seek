class AddOrderAndPersonIdToPublicationAuthors < ActiveRecord::Migration
  def self.up
    add_column :publication_authors, :author_index, :integer
    add_column :publication_authors, :person_id, :integer
  end

  def self.down
    remove_column :publication_authors, :person_id
    remove_column :publication_authors, :author_index
  end
end
