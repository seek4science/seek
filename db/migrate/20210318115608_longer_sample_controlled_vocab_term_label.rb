class LongerSampleControlledVocabTermLabel < ActiveRecord::Migration[5.2]
  def up
    change_column :sample_controlled_vocab_terms, :label, :text
  end
  def down
    change_column :sample_controlled_vocab_terms, :label, :string
  end
end
