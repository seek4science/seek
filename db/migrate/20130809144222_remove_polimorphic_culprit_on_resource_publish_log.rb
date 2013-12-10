class RemovePolimorphicCulpritOnResourcePublishLog < ActiveRecord::Migration
  def up
    rename_column :resource_publish_logs, :culprit_id, :user_id
    remove_column :resource_publish_logs, :culprit_type
  end

  def down
    add_column :resource_publish_logs, :culprit_type, :string
    rename_column :resource_publish_logs, :user_id, :culprit_id
  end
end
