class AddShowGuideBoxColumnToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :show_guide_box, :boolean, :default => true
  end

  def self.down
    remove_column :users, :show_guide_box
  end
end
