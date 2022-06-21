class AddDataTypeToDataFiles < ActiveRecord::Migration[5.2]
  def change
    add_column :data_files, :data_type, :string, :default => "http://edamontology.org/data_0006", :null => false
    add_column :data_files, :format_type, :string, :default => "http://edamontology.org/format_1915", :null => false
    add_column :data_files, :file_template_id, :integer
  end
end
