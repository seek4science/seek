class CreateAssaysStudies < ActiveRecord::Migration
  def self.up
    create_table :assays_studies,:id=>false do |t|
      t.integer :assay_id
      t.integer :study_id
    end
  end

  def self.down
    drop_table :assays_studies
  end
  
end
