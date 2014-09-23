class AddSomeFieldsInScalesIfMissing < ActiveRecord::Migration
  def change
    add_column(:scales, :key, :string) unless column_exists?(:scales, :key, :string)
    add_column(:scales, :pos, :integer, :default=> 1) unless column_exists?(:scales, :pos, :integer)
    add_column(:scales, :image_name, :string) unless column_exists?(:scales, :image_name, :string)
  end
end
