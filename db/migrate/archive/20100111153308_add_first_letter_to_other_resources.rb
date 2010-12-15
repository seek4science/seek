class AddFirstLetterToOtherResources < ActiveRecord::Migration
  def self.up
    add_column :data_files,:first_letter,:string,:limit => 1
    add_column :data_file_versions,:first_letter,:string,:limit => 1
    add_column :models,:first_letter,:string,:limit => 1
    add_column :model_versions,:first_letter,:string,:limit => 1
    add_column :sops,:first_letter,:string,:limit => 1
    add_column :sop_versions,:first_letter,:string,:limit => 1
    add_column :assays,:first_letter,:string,:limit => 1
    add_column :studies,:first_letter,:string,:limit => 1
    add_column :investigations,:first_letter,:string,:limit => 1    
  end

  def self.down
    remove_column :data_files,:first_letter
    remove_column :models,:first_letter
    remove_column :sops,:first_letter
    remove_column :data_file_versions,:first_letter
    remove_column :model_versions,:first_letter
    remove_column :sop_versions,:first_letter
    remove_column :assays,:first_letter
    remove_column :studies,:first_letter
    remove_column :investigations,:first_letter    
  end
end
