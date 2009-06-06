class ChangeStudyAssayToOneToMany < ActiveRecord::Migration
  def self.up
    add_column :assays, :study_id, :integer
    drop_table :assays_studies
  end

  def self.down
    remove_column :assays,:study_id
    create_table :assays_studies, :id => false do |t|
      t.integer :assay_id
      t.integer :study_id
    end
  end
end
