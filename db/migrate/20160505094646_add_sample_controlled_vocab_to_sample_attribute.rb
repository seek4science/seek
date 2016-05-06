class AddSampleControlledVocabToSampleAttribute < ActiveRecord::Migration
  def change
    add_column :sample_attributes,:sample_controlled_vocab_id,:integer
  end
end
