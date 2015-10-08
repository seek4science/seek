class AddActivatedFlagToProgramme < ActiveRecord::Migration
  def change
    add_column :programmes, :activated, :boolean, :default=>false
  end
end
