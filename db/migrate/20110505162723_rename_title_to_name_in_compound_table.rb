class RenameTitleToNameInCompoundTable < ActiveRecord::Migration
  def self.up
    rename_column :compounds,:title, :name
  end

  def self.down
    rename_column :compounds,:name, :title
  end
end
