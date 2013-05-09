class ChangeSpecSexFromBooleanToInteger < ActiveRecord::Migration
  def self.up
    change_column :specimens, :sex, :integer
  end

  def self.down
    change_column :specimens, :sex, :boolean
  end
end
