class ChangeAssayTitleToText < ActiveRecord::Migration[5.2]
  def up
    change_column :assays,:title,:text
  end

  def down
    change_column :assays,:title,:string
  end
end
