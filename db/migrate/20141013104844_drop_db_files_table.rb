class DropDbFilesTable < ActiveRecord::Migration
  def up
    drop_table :db_files
  end

  def down
    create_table "db_files", :force => true do |t|
      t.binary "data", :limit => 2147483647
    end
  end
end
