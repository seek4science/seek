class RenameDonorNumberToTitleInSpecimens < ActiveRecord::Migration
  def self.up
    rename_column :specimens,:donor_number, :title
  end

  def self.down
    rename_column :specimens,:title, :donor_number
  end
end
