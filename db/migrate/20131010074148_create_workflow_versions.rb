class CreateWorkflowVersions < ActiveRecord::Migration
  def change
    create_table :workflow_versions do |t|
      t.string :title
      t.text :description
      t.belongs_to :category
      t.references :contributor, :polymorphic => true
      t.string :uuid
      t.references :policy
      t.text :other_creators
      t.string :first_letter, :limit => 1
      t.timestamps
      t.datetime :last_used_at
      t.references :workflow
      t.text :revision_comments
    end
  end
end
