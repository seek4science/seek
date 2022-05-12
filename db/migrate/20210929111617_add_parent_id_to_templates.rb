class AddParentIdToTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :templates,:parent_id, :integer
  end
end
