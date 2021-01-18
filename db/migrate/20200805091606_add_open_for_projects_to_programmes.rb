class AddOpenForProjectsToProgrammes < ActiveRecord::Migration[5.2]
  def change
    add_column :programmes, :open_for_projects, :boolean, default: false
  end
end
