class RemoveRequiredFromSampleControlledVocab < ActiveRecord::Migration[6.1]
  def change
    remove_column :sample_controlled_vocabs, :required , :boolean
  end
end
