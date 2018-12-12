
class CreateWorkflowsSopsJoinTable < ActiveRecord::Migration
def change

  # If you want to add an index for faster querying through this join:
  create_join_table :workflows, :sops do |t|
    t.index :workflow_id
    t.index :sop_id
  end
end
end
