class RenameSampleAccessorName < ActiveRecord::Migration[5.2]
  def change
    rename_column :sample_attributes, :accessor_name, :original_accessor_name
  end
end
