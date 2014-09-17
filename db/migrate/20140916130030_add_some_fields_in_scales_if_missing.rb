class AddSomeFieldsInScalesIfMissing < ActiveRecord::Migration
  def change
    add_column :scales, :key, :string if !column_exists?(:scales, :key, :string)
    add_column :scales, :pos, :integer, :default=> 1 if !column_exists?(:scales, :key, :integer)
    add_column :scales, :image_name, :string if !column_exists?(:scales, :image_name, :string)
  end
end
