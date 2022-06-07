class AddIsaTagToSampleAttributes < ActiveRecord::Migration[5.2]
  def change
    add_column :sample_attributes, :isa_tag_id, :integer
  end
end