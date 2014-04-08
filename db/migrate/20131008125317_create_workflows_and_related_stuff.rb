class CreateWorkflowsAndRelatedStuff < ActiveRecord::Migration
  def change
    create_table :workflows do |t|
      t.string :title
      t.text :description
      t.belongs_to :category
      t.references :contributor, :polymorphic => true
      t.string :uuid
      t.references :policy
      t.text :other_creators
      t.string :first_letter, :limit => 1
      t.timestamps
    end

    create_table :workflow_categories do |t|
      t.string :name
    end

    create_table :workflow_input_port_types do |t|
      t.string :name
    end

    create_table :workflow_output_port_types do |t|
      t.string :name
    end

    create_table :workflow_input_ports do |t|
      t.string :name
      t.text :description
      t.belongs_to :type
      t.text :example_value
      t.belongs_to :example_data_file
    end

    create_table :workflow_output_ports do |t|
      t.string :name
      t.text :description
      t.belongs_to :type
      t.text :example_value
      t.belongs_to :example_data_file
    end
  end
end