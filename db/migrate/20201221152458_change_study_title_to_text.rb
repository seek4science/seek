class ChangeStudiesTitleToText < ActiveRecord::Migration[5.2]
  def up
    change_column :studies,:title,:text
  end

  def down
    change_column :studies,:title,:string
  end
end
