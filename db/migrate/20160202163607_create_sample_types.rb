class CreateSampleTypes < ActiveRecord::Migration
  def change
    create_table :sample_types do |t|
      t.string :title
      t.text :attr_definitions
      t.string :uuid

      t.timestamps
    end
  end
end
