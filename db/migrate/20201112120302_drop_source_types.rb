class DropSourceTypes < ActiveRecord::Migration[5.2]
  def change
    drop_table :source_types
  end
end
