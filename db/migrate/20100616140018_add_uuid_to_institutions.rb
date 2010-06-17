class AddUuidToInstitutions < ActiveRecord::Migration
  def self.up
    add_column :institutions, :uuid, :string
  end

  def self.down
    remove_column :institutions,:uuid
  end
end
