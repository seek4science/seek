class IncreaseDbFilesSizeLimit < ActiveRecord::Migration
  def self.up
    change_column :db_files,:data,:binary,:limit=>40.megabytes
  end

  def self.down
    change_column :db_files,:data,:binary,:limit=>65535.bytes
  end
end
