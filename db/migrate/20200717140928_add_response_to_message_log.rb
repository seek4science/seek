class AddResponseToMessageLog < ActiveRecord::Migration[5.2]
  def change
    add_column :message_logs, :response,:text, default:nil
  end
end
