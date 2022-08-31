class RenameTempalteVersion < ActiveRecord::Migration[6.1]
  def change
		rename_column :templates, :template_version, :version
  end
end
