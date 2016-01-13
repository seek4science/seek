class AddZenodoDepositionIdToSnapshots < ActiveRecord::Migration
  def change
    change_table :snapshots do |t|
      t.string :zenodo_deposition_id
    end
  end
end
