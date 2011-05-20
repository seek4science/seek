class DropCanEditInstitutionsFieldOnUser < ActiveRecord::Migration
  def self.up
    remove_column :users,:can_edit_institutions
  end

  def self.down
    add_column :users,:can_edit_institutions,:boolean,:default=>false
  end
end
