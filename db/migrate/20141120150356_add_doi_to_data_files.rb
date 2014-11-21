class AddDoiToDataFiles < ActiveRecord::Migration
  def change
    add_column :data_files,:doi,:string
  end
end
