class AddMediumTitleToTreatments < ActiveRecord::Migration
  def change
    add_column :treatments,:medium_title,:string
  end
end
