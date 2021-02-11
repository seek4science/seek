class ChangeMessageLogResourceToSubject < ActiveRecord::Migration[5.2]
  def change
    rename_column :message_logs, :resource_id, :subject_id
    rename_column :message_logs, :resource_type, :subject_type
  end
end
