class AddExceptionToTask < ActiveRecord::Migration[6.1]
  def change
    add_column :tasks, :exception, :text
  end
end
