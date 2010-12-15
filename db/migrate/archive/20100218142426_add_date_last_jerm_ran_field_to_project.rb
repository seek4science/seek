class AddDateLastJermRanFieldToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :last_jerm_run,:datetime
  end

  def self.down
    remove_column :projects,:last_jerm_run
  end
  
end
