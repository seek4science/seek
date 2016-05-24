class AddOriginatingDataFileToSample < ActiveRecord::Migration
  def change
    add_column :samples, :originating_data_file_id, :integer
  end
end
