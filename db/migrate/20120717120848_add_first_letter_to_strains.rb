class AddFirstLetterToStrains < ActiveRecord::Migration
  def self.up
    add_column :strains, :first_letter, :string
  end

  def self.down
    remove_column :strains, :first_letter
  end
end
