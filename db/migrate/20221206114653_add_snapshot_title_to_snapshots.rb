class AddSnapshotTitleToSnapshots < ActiveRecord::Migration[6.1]
  def change
    add_column :snapshots, :title, :string
    add_column :snapshots, :description, :text
  end
end
