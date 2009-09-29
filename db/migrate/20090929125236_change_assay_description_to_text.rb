class ChangeAssayDescriptionToText < ActiveRecord::Migration
  def self.up
    change_column :assays, :description, :text
  end

  def self.down
    change_column :assays, :description, :string
  end
end