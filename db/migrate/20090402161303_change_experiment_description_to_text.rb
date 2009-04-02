class ChangeExperimentDescriptionToText < ActiveRecord::Migration
  def self.up
    change_column :experiments, :description, :text
  end

  def self.down
    change_column :experiments, :description, :string
  end
end
