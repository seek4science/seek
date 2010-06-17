class AddUuidToInvestigations < ActiveRecord::Migration
  def self.up
    add_column :investigations, :uuid, :string
  end

  def self.down
    remove_column :investigations,:uuid
  end
end
