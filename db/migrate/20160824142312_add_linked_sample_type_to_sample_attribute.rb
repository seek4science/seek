class AddLinkedSampleTypeToSampleAttribute < ActiveRecord::Migration
  def change
    add_column :sample_attributes,:linked_sample_type_id,:integer
  end
end
