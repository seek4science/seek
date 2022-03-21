class RemoveProjectHierarchyReferences < ActiveRecord::Migration[6.1]
  def change
    drop_table "project_descendants" do |t|
      t.integer "ancestor_id"
      t.integer "descendant_id"
    end

    remove_column :projects, :ancestor_id, :integer
    remove_column :projects, :parent_id, :integer
  end
end
