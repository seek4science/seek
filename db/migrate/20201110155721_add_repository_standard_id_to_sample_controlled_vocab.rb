class AddRepositoryStandardIdToSampleControlledVocab < ActiveRecord::Migration[5.2]
  def change
    add_column :sample_controlled_vocabs, :repository_standard_id, :integer
  end
end
