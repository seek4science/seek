class CreateAssayClasses < ActiveRecord::Migration
  def self.up
    create_table :assay_classes do |t|
      t.string   :title
      t.text     :description
      t.timestamps
    end
  end

  def self.down
    drop_table :assay_classes
  end
end
