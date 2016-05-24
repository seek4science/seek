class CreateSampleControlledVocabTerms < ActiveRecord::Migration
  def change
    create_table :sample_controlled_vocab_terms do |t|
      t.string :label
      t.integer :sample_controlled_vocab_id

      t.timestamps
    end
  end
end
