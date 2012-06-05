class AddUuidToStrains < ActiveRecord::Migration
  def self.up
    add_column :strains, :uuid, :string
  end

  def self.down
    remove_column :strains,:uuid
  end
end
