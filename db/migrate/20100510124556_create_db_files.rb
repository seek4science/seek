class CreateDbFiles < ActiveRecord::Migration
  def self.up
    create_table :db_files do |t|
      t.binary :data
    end
  end

  def self.down
    drop_table :db_files
  end
end
