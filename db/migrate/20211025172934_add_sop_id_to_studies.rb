class AddSopIdToStudies < ActiveRecord::Migration[5.2]
  def change
    add_column :studies, :sop_id, :integer
  end
end
