class SampleTypesStudies < ActiveRecord::Migration[5.2]
  def change
    create_table :sample_types_studies do |t|
      t.references :sample_type
      t.references :study
    end
  end
end
