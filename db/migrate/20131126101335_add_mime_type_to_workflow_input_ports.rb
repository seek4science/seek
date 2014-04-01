class AddMimeTypeToWorkflowInputPorts < ActiveRecord::Migration
    def change
      change_table :workflow_input_ports do |t|
        t.string :mime_type
      end
    end
  end
