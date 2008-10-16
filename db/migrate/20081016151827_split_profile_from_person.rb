class SplitProfileFromPerson < ActiveRecord::Migration
  def self.up
    remove_column :people, :fist_name
    remove_column :people, :last_name
    remove_column :people, :email
    remove_column :people, :web_page
    remove_column :people, :skype_name
    remove_column :people, :phone
    
  end

  def self.down
    add_column :people, :first_name, :string
    add_column :people, :last_name, :string
    add_column :people, :email, :string
    add_column :people, :web_page, :string
    add_column :people, :skype_name, :string
    add_column :people, :phone, :string
  end
end
