class RemoveFormatAndDataTypeAttributes < ActiveRecord::Migration[6.1]
  def change
    remove_column :data_files, :data_type, :string, default: "http://edamontology.org/data_0006", null: false
    remove_column :data_files, :format_type, :string, default: "http://edamontology.org/data_1915", null: false
    remove_column :file_templates, :data_type, :string, default: "http://edamontology.org/data_0006", null: false
    remove_column :file_templates, :format_type, :string, default: "http://edamontology.org/data_1915", null: false
    remove_column :placeholders, :data_type, :string, default: "http://edamontology.org/data_0006", null: false
    remove_column :placeholders, :format_type, :string, default: "http://edamontology.org/data_1915", null: false
  end
end
