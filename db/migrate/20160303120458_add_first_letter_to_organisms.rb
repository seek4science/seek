class AddFirstLetterToOrganisms < ActiveRecord::Migration
  def change
    add_column :organisms, :first_letter, :string
  end
end
