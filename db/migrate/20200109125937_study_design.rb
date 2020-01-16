class StudyDesigns < ActiveRecord::Migration[5.2]
  def change
    create_table :study_designs do |t|
      t.integer :study_id
      t.text :data
      t.text :flowchart
      t.text :methods
      t.text :tables
      t.timestamps
    end
    add_index :study_design, [ :study_id], name: 'index_study_id'
  end
end
