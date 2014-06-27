class ChangeSpecimenFieldsToStrings < ActiveRecord::Migration
  def self.up
    change_table :specimens do |t|
      t.change :confluency, :string
      t.change :passage, :string
      t.change :purity, :string
      t.change :viability, :string
    end
  end

  def self.down
    change_table :specimens do |t|
      t.change :confluency, :float
      t.change :passage, :integer
      t.change :viability, :float
      t.change :purity, :float
    end
  end
end
