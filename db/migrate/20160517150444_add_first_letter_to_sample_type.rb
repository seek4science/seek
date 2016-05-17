class AddFirstLetterToSampleType < ActiveRecord::Migration
  def change
    add_column :sample_types, :first_letter, :string, :limit=>1
  end
end
