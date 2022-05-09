class RemoveFactorsStudiedFromUnit < ActiveRecord::Migration[5.2]
  def change
    remove_column :units, :factors_studied, :boolean, default: true
  end
end
