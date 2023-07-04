class SopsStudies < ActiveRecord::Migration[6.1]
  def change
    create_table :sops_studies do |t|
      t.references :sop
      t.references :study
    end
  end
end
