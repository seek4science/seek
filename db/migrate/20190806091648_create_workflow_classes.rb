class CreateWorkflowClasses < ActiveRecord::Migration[5.2]
  def change
    create_table :workflow_classes do |t|
      t.string :title
      t.text :description
      t.string :key

      t.timestamps null:true
    end
  end
end
