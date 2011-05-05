class RenameTitleToNameInCompoundTable < ActiveRecord::Migration
  def self.up
    rename_column :compounds,:title, :name
  end

  def self.down
  end
end
