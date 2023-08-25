class ChangeDefaultGroupInTemplates < ActiveRecord::Migration[6.1]
  def change
    change_column_default(:templates, :group, from: 'other', to: 'Project specific templates')
  end
end
