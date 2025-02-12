class AddSnapshotTitleToSnapshots < ActiveRecord::Migration[7.2]
  def change
    add_column :snapshots, :title, :string
    add_column :snapshots, :description, :text
  end
end
