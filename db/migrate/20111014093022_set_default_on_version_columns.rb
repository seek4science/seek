class SetDefaultOnVersionColumns < ActiveRecord::Migration
  #MERGENOTE - we have a problem with this migration with sqlite3
  def self.up
    change_column_default :data_files, :version, 1
    change_column_default :models, :version, 1
    change_column_default :sops, :version, 1
  end

  def self.down
    change_column_default :data_files, :version, nil
    change_column_default :sops, :version, nil
    change_column_default :models, :version, nil
  end
end
