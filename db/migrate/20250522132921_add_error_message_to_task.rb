class AddErrorMessageToTask < ActiveRecord::Migration[7.2]
  def change
    add_column :tasks, :error_message, :text
  end
end
