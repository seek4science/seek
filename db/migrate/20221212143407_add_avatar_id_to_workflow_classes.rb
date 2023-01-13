class AddAvatarIdToWorkflowClasses < ActiveRecord::Migration[6.1]
  def change
    add_column :workflow_classes, :avatar_id, :integer
  end
end
