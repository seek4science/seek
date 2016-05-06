class AddPosToSampleAttributes < ActiveRecord::Migration
  def change
    add_column :sample_attributes, :pos, :integer
  end
end
