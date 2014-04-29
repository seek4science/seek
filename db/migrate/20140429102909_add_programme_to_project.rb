class AddProgrammeToProject < ActiveRecord::Migration
  def change
    add_column :projects,:programme_id,:integer
  end
end
