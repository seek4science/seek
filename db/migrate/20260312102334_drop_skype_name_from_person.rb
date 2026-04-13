class DropSkypeNameFromPerson < ActiveRecord::Migration[7.2]
  def change
    remove_column :people, :skype_name, :string
  end
end
