class CreatePublications < ActiveRecord::Migration
  def self.up
    create_table :publications do |t|
      t.text  :title
      t.text  :abstract
      t.date  :published_date
      t.string :journal
      
      t.timestamps
    end
  end

  def self.down
    drop_table :publications
  end
end
