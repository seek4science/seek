class CreateFlowcharts < ActiveRecord::Migration[5.2]
  def change
    create_table :flowcharts do |t|
      t.references :study, index: {unique: true}, null: false
      t.integer :source_sample_type_id
      t.string :assay_sample_type
      t.string :items
      t.timestamps
    end
  end
end
