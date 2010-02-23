# This migration is required to give users access rights to edit entries
# for projects/institutions they are working in/with, but none of the rest.
#
# These fields will deny making any changes by default, but can be set by admins
# in "edit profile" screen for "person" object where the desired user is attached to. 

class AddFlagsToAllowEditingProjectsAndInstitutionsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :can_edit_projects, :boolean, :default => false
    add_column :users, :can_edit_institutions, :boolean, :default => false
  end

  def self.down
    remove_column :users, :can_edit_projects
    remove_column :users, :can_edit_institutions
  end
end
