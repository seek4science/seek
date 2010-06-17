class AddUuidToStudies < ActiveRecord::Migration
  def self.up
    add_column :studies, :uuid, :string
  end

  def self.down
    remove_column :studies,:uuid
  end
end
