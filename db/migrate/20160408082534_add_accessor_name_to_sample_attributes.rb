class AddAccessorNameToSampleAttributes < ActiveRecord::Migration
  def change
    add_column :sample_attributes, :accessor_name, :string
  end
end
