class DropSourceAttributes < ActiveRecord::Migration[5.2]
  def change
    drop_table :source_attributes
  end
end
