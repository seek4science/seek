class AddErrorToGalaxyItem < ActiveRecord::Migration[5.2]
  def change
    add_column :galaxy_execution_queue_items, :error, :string
  end
end
