class CreateSampleControlledVocabs < ActiveRecord::Migration
  def change
    create_table :sample_controlled_vocabs do |t|
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
