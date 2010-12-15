class CreateHelpDocuments < ActiveRecord::Migration
  def self.up
    create_table :help_documents do |t|
      t.string :identifier
      t.string :title
      t.text :body
      t.timestamps
    end
  end

  def self.down
    drop_table :help_documents
  end
end
