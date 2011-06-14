class AddInstitutionToAssays < ActiveRecord::Migration
  def self.up
    add_column :assays,:institution_id,:integer
  end

  def self.down
    remove_column :assays,:institution_id
  end
end
