class AddSnapshotTitleToSnapshots < ActiveRecord::Migration[6.1]
  def change
    add_column :snapshots, :snapshot_title, :string
    add_column :snapshots, :snapshot_description, :text
  end
end
