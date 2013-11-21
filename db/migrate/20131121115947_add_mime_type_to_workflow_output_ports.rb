class AddMimeTypeToWorkflowOutputPorts < ActiveRecord::Migration
  def change
    change_table :workflow_output_ports do |t|
      t.string :mime_type
    end
  end
end
