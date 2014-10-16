class RemoveLimitFromDbFileData < ActiveRecord::Migration
  def up
    change_column :db_files,:data,:binary,:limit=>nil
  end

  def down
    change_column :db_files,:data,:binary,:limit => 2147483647
  end
end
