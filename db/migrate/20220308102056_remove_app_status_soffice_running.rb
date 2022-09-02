class RemoveAppStatusSofficeRunning < ActiveRecord::Migration[5.2]
  def change
    remove_column :application_status, :soffice_running, :boolean
  end
end
