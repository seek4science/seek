class RemoveAssayInstitution < ActiveRecord::Migration[6.1]
  def change
    remove_column :assays, :institution_id, :integer
  end
end
