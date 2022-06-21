class SetDefaultOnTemplatesColumns < ActiveRecord::Migration[5.2]
  def change
    change_column :templates, :level, :string, :default => "other"
    change_column :templates, :organism, :string, :default => "other"
    change_column :templates, :group, :string, :default => "other"
  end
end
