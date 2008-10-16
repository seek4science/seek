class UpdateWorkGroupFields < ActiveRecord::Migration
  def self.up
    rename_column :work_groups, :group_name, :name
    remove_column :work_groups, :country
    remove_column :work_groups, :city
    remove_column :work_groups, :address
    remove_column :work_groups, :web_page
    add_column :work_groups, :institution_id, :integer
    add_column :work_groups, :project_id, :integer
    
  end
  
 

  def self.down
    rename_column :work_groups,  :name, :group_name
    add_column :work_groups, :country, :string
    add_column :work_groups, :city, :string
    add_column :work_groups, :address, :text
    add_column :work_groups, :web_page, :string
    remove_column :work_groups, :institution_id
    remove_column :work_groups, :project_id
  end
end
