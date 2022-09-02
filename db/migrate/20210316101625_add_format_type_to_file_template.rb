class AddFormatTypeToFileTemplate < ActiveRecord::Migration[5.2]
  def change
    add_column :file_templates, :format_type, :string, null: false, default: 'http://edamontology.org/format_1915'
  end
end
