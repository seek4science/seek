class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.string :group_name
      t.string :country
      t.string :city
      t.text :address
      t.string :web_page

      t.timestamps
    end
  end

  def self.down
    drop_table :groups
  end
end
