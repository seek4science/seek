class CreateTestModels < ActiveRecord::Migration
  def self.up
    create_table :books, :force => true do |t|
      t.string :title
      t.string :author_name
      t.string :isbn
      t.integer :pub_year
      t.text :summary
    end
    
    create_table :chapters, :force => true do |t|
      t.integer :chapter_number
      t.string :title
      t.text :summary
      t.integer :book_id
    end
    
    create_table :users, :force => true do |t|
      t.string :name
    end
    
    create_table :groups, :force => true do |t|
      t.string :name
    end
    
    create_table :tags, :force => true do |t|
      t.string :name, :null => false
    end
    add_index :tags, [ :name ], :unique => true
  end

  def self.down
    drop_table :books
    drop_table :chapters
    drop_table :users
    drop_table :groups
  end
end