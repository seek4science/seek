class AddUuidToModels < ActiveRecord::Migration
  def self.up
    add_column :models, :uuid, :string
  end

  def self.down
    remove_column :models,:uuid
  end
end
