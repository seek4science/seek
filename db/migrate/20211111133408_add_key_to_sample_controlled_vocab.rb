class AddKeyToSampleControlledVocab < ActiveRecord::Migration[5.2]
  def change
    add_column :sample_controlled_vocabs, :key, :string
  end
end
