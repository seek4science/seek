class CreateSourceTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :source_types do |t|
      t.string :name
      t.string :group
      t.integer :source_type  #sorce characteristics or assay type
    end
  end
end
