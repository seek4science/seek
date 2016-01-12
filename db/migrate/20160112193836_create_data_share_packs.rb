class CreateDataSharePacks < ActiveRecord::Migration
  def change
    create_table :data_share_packs do |t|
      t.string :title
      t.string :description

      t.timestamps
    end
  end
end
