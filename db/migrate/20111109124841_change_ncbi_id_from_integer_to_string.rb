class ChangeNcbiIdFromIntegerToString < ActiveRecord::Migration
  def self.up
    change_column :organisms, :ncbi_id, :string
  end

  def self.down
    change_column :organisms, :ncbi_id, :integer
  end
end
