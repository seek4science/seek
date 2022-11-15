class AddDataTypeToFileTemplate < ActiveRecord::Migration[5.2]
  def change
    add_column :file_templates, :data_type, :string, null: false, default: 'http://edamontology.org/data_0006'
  end
end
