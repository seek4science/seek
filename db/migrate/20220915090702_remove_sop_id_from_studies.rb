class RemoveSopIdFromStudies < ActiveRecord::Migration[6.1]
  def change
    remove_column :studies, :sop_id, :integer
  end
end
