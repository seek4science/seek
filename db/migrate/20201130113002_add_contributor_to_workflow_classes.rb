class AddContributorToWorkflowClasses < ActiveRecord::Migration[5.2]
  def change
    add_reference :workflow_classes, :contributor
  end
end
