class RemoveShowGuideBoxFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :show_guide_box
  end

  def down
    add_column :users, :show_guide_box, :boolean
  end
end
