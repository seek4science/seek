class DropProjectsPublication < ActiveRecord::Migration[5.2]
  def change
    drop_table :projects_publication
  end
end
