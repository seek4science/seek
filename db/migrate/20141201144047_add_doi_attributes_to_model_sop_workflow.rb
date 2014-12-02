class AddDoiAttributesToModelSopWorkflow < ActiveRecord::Migration
  def change
    add_column :models,:doi,:string
    add_column :model_versions,:doi,:string

    add_column :sops,:doi,:string
    add_column :sop_versions,:doi,:string

    add_column :workflows,:doi,:string
    add_column :workflow_versions,:doi,:string
  end
end
