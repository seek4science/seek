class AddFirstLetterToObsUnit < ActiveRecord::Migration[6.1]
  def change
    add_column :observation_units, :first_letter, :string, limit: 1
  end
end
