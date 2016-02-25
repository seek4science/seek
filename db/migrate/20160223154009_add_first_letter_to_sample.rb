class AddFirstLetterToSample < ActiveRecord::Migration
  def change
    add_column :samples, :first_letter, :string, :limit=>1
  end
end
