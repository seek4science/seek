class RenameTempalteVersion < ActiveRecord::Migration[6.1]
  def up
    if column_exists? :templates, :template_version
      rename_column :templates, :template_version, :version
    end
  end

  def down
    if column_exists? :templates, :version
      rename_column :templates, :version, :template_version
    end
  end
end
