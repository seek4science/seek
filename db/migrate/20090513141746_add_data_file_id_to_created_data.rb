class AddDataFileIdToCreatedData < ActiveRecord::Migration
  
  def self.up
    add_column :created_datas,:data_file_id,:integer
  end

  def self.down
    remove_column :created_datas,:data_file_id
  end

end
