class AddIndexesToSamples < ActiveRecord::Migration[7.2]
  def change
    add_index :samples, :originating_data_file_id
    add_index :samples, :sample_type_id
  end
end
