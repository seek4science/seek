class AddLimitToDbFileData < ActiveRecord::Migration
  begin
    def up
      change_column :db_files, :data, :binary, :limit => 2147483647
    end

    def down
      change_column :db_files, :data, :binary, :limit => nil
    end
  end
end

