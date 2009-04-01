class CreateAssayTypes < ActiveRecord::Migration
  def self.up
    create_table :assay_types do |t|
      t.string :title
      t.string :parent_assay_type_id
      t.timestamps
    end
  end

  def self.down
    drop_table :assay_types
  end
end
