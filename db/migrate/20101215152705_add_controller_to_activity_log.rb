class AddControllerToActivityLog < ActiveRecord::Migration
  
  def self.up
    add_column :activity_logs,:controller_name,:string
  end

  def self.down
    remove_column :activity_logs,:controller_name
  end
  
end
