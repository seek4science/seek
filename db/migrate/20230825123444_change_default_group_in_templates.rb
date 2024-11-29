class ChangeDefaultGroupInTemplates < ActiveRecord::Migration[6.1]
  def change
    change_column_default(:templates, :group, from: 'other', to: 'Project specific templates')
    change_column_default(:templates, :level, from: 'other', to: nil)
    change_column_default(:templates, :organism, from: 'other', to: 'any')
  end
end
